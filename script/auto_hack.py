import json
import re
import subprocess
import sys
import os
from copy import deepcopy
import datetime
import glob
import tempfile
import base64

# ANSI Color
RESET = "\033[0m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
MAGENTA = "\033[35m"
GRAY = "\033[90m"

# DEFAULT_INJECT_PARAM 参数说明 / Injection parameters:
# --inplace             # 就地修改目标文件，不创建新副本 / Modify the original file directly (in-place editing)
# --weak                # 以弱依赖方式注入动态库，失败不会导致崩溃 / Inject the dylib as a weak dependency (fail-safe)
# --all-yes             # 所有提示默认选择“Yes”，适合自动化脚本 / Automatically answer "yes" to all prompts
# --no-strip-codesig    # 保留原始签名，不去除 / Preserve the original code signature
DEFAULT_INJECT_PARAM = "--inplace --weak --all-yes --no-strip-codesig"

# DEFAULT_RE_SIGN_PARAM 参数说明 / Re-signing parameters:
# -f / --force               # 强制覆盖已有签名 / Force replace existing code signature
# -s -                       # 使用 ad-hoc 签名，不依赖证书 / Use ad-hoc signature (no identity required)
# --all-architectures        # 针对所有架构签名（如 arm64 和 x86_64）/ Sign all architectures (e.g., arm64 + x86_64)
# --deep                     # 递归签名整个 app bundle，包括 frameworks、插件等 / Deep sign the entire bundle recursively
DEFAULT_RE_SIGN_PARAM = "-f -s - --all-architectures --deep"

DEFAULT_INJECT_TYPE = "static"

current_dir = os.path.dirname(os.path.abspath(__file__))
apps_json_path = os.path.join(current_dir, "apps.json")
apps_schema_path = os.path.join(current_dir, "apps.schema.json")
insert_dylib = f"{current_dir}/../tools/insert_dylib"
mac_patch_helper = f"{current_dir}/../tools/mac_patch_helper"
dylib_name = "libdylib_dobby_hook.dylib"
release_dylib = f"{current_dir}/../release/{dylib_name}"

# Check and install jsonschema if not available
try:
    from jsonschema import validate, ValidationError  # Import validation library
except ModuleNotFoundError:
    print("jsonschema is not installed. Installing it now...")
    subprocess.check_call(
        [
            sys.executable,
            "-m",
            "pip",
            "install",
            "jsonschema",
            "--break-system-packages",
        ]
    )
    from jsonschema import validate, ValidationError  # Retry import after installation

with open(apps_schema_path, "r", encoding="utf-8") as schema_file:
    schema = json.load(schema_file)


def _timestamp():
    return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def log_info(message):
    print(f"{GREEN}🟢 [{_timestamp()}] [INFO] {message}{RESET}")


def log_warning(message):
    print(f"{YELLOW}🟡 [{_timestamp()}] [WARN] {message}{RESET}")


def log_error(message):
    print(f"{RED}🔴 [{_timestamp()}] [ERROR] {message}{RESET}")


def log_plain(message):
    """
    Log a plain message without any colors or formatting.
    """
    print(message)


def log_command(cmd):
    log_plain(f"➜ {cmd}")


def log_separator(app_name=None):
    """
    Print a separator line with an optional centered title.
    Automatically adapts to the terminal width.
    """
    try:
        terminal_width = os.get_terminal_size().columns
    except OSError:
        terminal_width = 80
    terminal_width = int(terminal_width * 0.96)
    if app_name:
        title = f" 📦 Processing App: {app_name} "
        separator_length = (terminal_width - len(title)) // 2
        separator = "=" * separator_length
        print(f"{MAGENTA}{separator}{title}{separator}{RESET}")
    else:
        print(f"{GRAY}{'=' * terminal_width}{RESET}")


def resolve_variables(data, context=None):
    if context is None:
        context = {}

    if isinstance(data, dict):
        result = {}
        local_context = deepcopy(context)
        for key, value in data.items():
            # Build context (process value first, then record available variables)
            resolved_value = resolve_variables(value, local_context)
            result[key] = resolved_value
            if isinstance(resolved_value, (str, int, float, bool)):
                local_context[key] = resolved_value
        return result

    elif isinstance(data, list):
        return [resolve_variables(item, context) for item in data]

    elif isinstance(data, str):

        def replace_var(match):
            var_name = match.group(1)
            return str(context.get(var_name, match.group(0)))

        return re.sub(r"\$(\w+)", replace_var, data)

    else:
        return data


def load_and_merge_apps_json(directory):
    """
    Scan the given directory for all files ending with 'apps.json',
    load them, and merge their contents into a single dictionary.
    """
    merged_data = {"apps": []}
    json_files = glob.glob(os.path.join(directory, "*apps.json"))

    if not json_files:
        log_error(f"No *apps.json files found in the [{directory}]!")
        sys.exit(1)

    for json_file in json_files:
        log_info(f"Loading JSON file: {json_file}")
        with open(json_file, "r", encoding="utf-8") as f:
            try:
                data = json.load(f)
                if "apps" in data and isinstance(data["apps"], list):
                    merged_data["apps"].extend(data["apps"])
                else:
                    log_warning(
                        f"File {json_file} does not contain a valid 'apps' list."
                    )
            except json.JSONDecodeError as e:
                log_error(f"Failed to parse JSON file: {json_file}")
                log_error(f"Error: {e}")

    log_info(f"Merged {len(json_files)} JSON files.")
    return merged_data


def run_cmd_or_raise(cmd, cwd=None):
    """
    Run a shell command and raise an exception if it fails.
    Outputs only the relevant error message to keep logs concise.
    """
    log_command(cmd)
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
            text=True,
        )
        if result.stdout.strip():
            log_plain(f"🗒️ Standard Output:\n{result.stdout.strip()}")
        if result.stderr.strip():
            log_plain(f"⚠️ Standard Error:\n{result.stderr.strip()}")
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed: {cmd}")
        log_error(f"Exit code: {e.returncode}")
        log_error(f"Error output: {e.stderr.strip()}")
        raise RuntimeError(
            f"Command failed with exit code {e.returncode}. See logs for details."
        )


def run_cmd_ignore_error(cmd, cwd=None):
    """
    Run a shell command and ignore any errors.
    Logs warnings instead of raising exceptions.
    """

    log_command(cmd)

    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
            text=True,
        )
        if result.stdout.strip():
            log_plain(f"🗒️ Standard Output:\n{result.stdout.strip()}")
        if result.stderr.strip():
            log_plain(f"⚠️ Standard Error:\n{result.stderr.strip()}")
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        log_warning(f"Command failed but ignoring: {cmd}")
        log_warning(f"Exit code: {e.returncode}")
        log_warning(f"Error output: {e.stderr.strip()}")
        return None  # Return None to indicate failure but continue execution


def run_cmd_ignore_output(cmd, cwd=None):
    """
    Run a shell command and return its output without printing it.
    """
    log_command(cmd)
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
            text=True,
        )
        return result.stdout.strip()  # Return the command's output
    except subprocess.CalledProcessError as e:
        log_warning(f"Command failed: {cmd}")
        log_warning(f"Exit code: {e.returncode}")
        log_warning(f"Error output: {e.stderr.strip()}")
        return None  # Return None to indicate failure


def run_cmd_silent(cmd, cwd=None):
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=cwd,
            text=True,
        )
        return result.stdout.strip()  # Return the command's output
    except subprocess.CalledProcessError as e:
        log_warning(f"Command failed: {cmd}")
        log_warning(f"Exit code: {e.returncode}")
        log_warning(f"Error output: {e.stderr.strip()}")
        return None  # Return None to indicate failure


def init_hack():
    """
    Initialize the hack by ensuring necessary files exist and setting permissions.
    """
    if not os.path.exists(release_dylib):
        log_error(f"Required file not found: {release_dylib}")
        raise FileNotFoundError(
            f"The required dylib file '{release_dylib}' does not exist. "
            "Please run 'bash build.sh' to compile it."
        )

    log_info(f"Setting permissions for: {insert_dylib}")
    run_cmd_ignore_output(f"chmod +x {insert_dylib}")
    run_cmd_ignore_output(f"/usr/bin/xattr -cr {insert_dylib}")

    log_info(f"Setting permissions for: {mac_patch_helper}")
    run_cmd_ignore_output(f"chmod +x {mac_patch_helper}")
    run_cmd_ignore_output(f"/usr/bin/xattr -cr {mac_patch_helper}")


def re_codesign(
    target_bin,
    re_sign_param,
    re_sign_entitlements=False,
    re_sign_entitlements_path=None,
):
    """
    Re-sign the given target path with the specified parameters.
    Outputs the current signature before and after re-signing.
    If re_sign_entitlements is True and no entitlements path is provided,
    export the original app's entitlements to a temporary file and use it.
    """
    # Determine the re-signing command
    if re_sign_entitlements_path:
        re_sign_cmd = f"sudo codesign {re_sign_param} --entitlements '{re_sign_entitlements_path}' '{target_bin}'"
    else:
        re_sign_cmd = f"sudo codesign {re_sign_param} '{target_bin}'"

    # Perform re-signing
    log_info(f"Re-signing: {target_bin}")
    run_cmd_ignore_error(re_sign_cmd)

    # Check signature after re-signing
    log_info(f"Checking signature after re-signing for: {target_bin}")
    run_cmd_ignore_error(f"sudo codesign -d -vvv --entitlements - '{target_bin}'")


def remove_quarantine_attribute(target_bin):
    """
    Remove the quarantine attribute from the specified target path.
    """
    log_info(f"Removing quarantine attribute for: {target_bin}")
    run_cmd_ignore_output(
        f"sudo /usr/bin/xattr -r -d com.apple.quarantine '{target_bin}'"
    )


def call_mac_patch_helper(fix_helper, bin_path, patches):
    """
    Call mac_patch_helper with the given parameters.
    Constructs a JSON payload, encodes it in Base64, and executes the command.
    """

    payload = {
        "fix_helper": fix_helper,
        "target_bin_path": bin_path,  # Add the target binary path
        "patches": patches,
    }

    payload_json = json.dumps(payload)
    payload_base64 = base64.b64encode(payload_json.encode("utf-8")).decode("utf-8")
    patch_cmd = f"{mac_patch_helper} --base64 '{payload_base64}'"
    run_cmd_or_raise(patch_cmd)


def export_entitlements(target_bin, entitlements_path=None):
    """
    Export entitlements from the target binary to a temporary file if no entitlements path is provided.
    Returns the path to the entitlements file.
    """
    if entitlements_path:
        log_info(f"Using provided entitlements file: {entitlements_path}")
        return entitlements_path

    # Create a temporary file for entitlements
    temp_entitlements = tempfile.NamedTemporaryFile(delete=False, suffix=".plist")
    temp_entitlements_path = temp_entitlements.name
    temp_entitlements.close()

    log_info(f"Exporting entitlements to temporary file: {temp_entitlements_path}")
    run_cmd_ignore_error(
        f"sudo codesign -d --entitlements - '{target_bin}' > '{temp_entitlements_path}'"
    )

    return temp_entitlements_path


def process_service(service, app_context):
    """
    Process a single service configuration.
    """
    app_path = app_context.get("app_path")
    app_framework_path = app_context.get("app_framework_path")
    service_name = service.get("service_name")
    re_sign_flag = app_context.get("re_sign", True)
    sm_privileged_executables = service.get("SMPrivilegedExecutables", service_name)
    service_bin_path = service.get("service_bin_path")
    inject_service = service.get("inject_service", False)
    fix_helper = service.get("fix_helper", True)
    patches = service.get("patches", [])
    re_sign_param = service.get("re_sign_param", DEFAULT_RE_SIGN_PARAM)
    re_sign_entitlements = service.get("re_sign_entitlements", False)
    re_sign_entitlements_path = service.get("re_sign_entitlements_path")

    log_info(f"Processing service: {service_name}")

    temp_entitlements_path = None
    if re_sign_flag and re_sign_entitlements:
        temp_entitlements_path = export_entitlements(
            service_bin_path, re_sign_entitlements_path
        )
        re_sign_entitlements_path = temp_entitlements_path

    # Kill related processes by service_name
    log_info(f"🔄 Killing processes related to service: {service_name}")
    run_cmd_ignore_output(f"sudo pkill -f '/{service_name}'")
    # Clean up old files
    log_info(f"🔄 Removing old {service_name} files...")
    run_cmd_ignore_output(
        f"sudo launchctl unload '/Library/LaunchDaemons/{service_name}.plist'"
    )
    run_cmd_ignore_output(f"sudo /usr/bin/killall -u root -9 '{service_name}'")
    run_cmd_ignore_output(f"sudo /bin/rm '/Library/LaunchDaemons/{service_name}.plist'")
    run_cmd_ignore_output(
        f"sudo /bin/rm '/Library/PrivilegedHelperTools/{service_name}'"
    )
    ## TODO bootout
    # launchctl list | grep -i snipast
    # 18965	0	application.com.Snipaste.113948205.113959944
    # sudo launchctl procinfo 18965 | grep domain
    # 18965	0	application.com.Snipaste.113948205.113959944
    # Usage: launchctl bootout <domain-target> [service-path1, service-path2, ...] | <service-target>
    # sudo launchctl bootout gui/$(id -u)/System/Library/LaunchDaemons/com.xxx.plist
    # sudo launchctl bootout gui/$(id -u)/application.com.Snipaste.113948205.113959944
    # run_cmd_ignore_output(
    #     f"sudo launchctl bootout gui/{os.getuid()}/Library/LaunchDaemons/{service_name}.plist"
    # )

    # if needed
    # run_cmd_ignore_output(f"sudo rm -rf '~/Library/Preferences/com.{service_name}.plist'")
    # run_cmd_ignore_output(f"sudo rm -rf '~/Library/Application Support/com.{service_name}'")

    # Handle injection
    if inject_service:
        re_sign_flag = True  # Enable re-signing for injected services
        log_info(f"Injecting dylib into service binary (static): {service_bin_path}")
        log_info(f"Checking signature before re-signing for: {service_bin_path}")
        run_cmd_ignore_error(
            f"sudo codesign -d -vvv --entitlements - '{service_bin_path}'"
        )
        if not check_dylib_exist(service_bin_path, dylib_name):
            inject_param = service.get("inject_param", DEFAULT_INJECT_PARAM)
            run_cmd_or_raise(
                f"sudo {insert_dylib} {inject_param} '{app_framework_path}/{dylib_name}' '{service_bin_path}'"
            )

    # Fix helper or apply patches
    if fix_helper or patches:
        log_info(f"Fixing helper or applying patches for service: {service_name}")
        call_mac_patch_helper(fix_helper, service_bin_path, patches)

    # Handle re-signing
    if re_sign_flag:
        # Modify Info.plist
        log_info(f"🔧 Modifying Info.plist for {service_name}...")
        identifier_name = f'identifier \\"{service_name}\\"'
        requirements_name = identifier_name
        plist_path = f"{app_path}/Contents/Info.plist"
        run_cmd_or_raise(
            f"sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' '{plist_path}'"
        )
        run_cmd_ignore_output(
            f"sudo /usr/libexec/PlistBuddy -c 'Set :SMPrivilegedExecutables:{sm_privileged_executables} \"{requirements_name}\"' '{plist_path}'"
        )
        run_cmd_or_raise(
            f"sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' '{plist_path}'"
        )

        log_info(f"Re-signing service: {service_name}")
        re_codesign(
            service_bin_path,
            re_sign_param,
            re_sign_entitlements,
            re_sign_entitlements_path,
        )
        if temp_entitlements_path:
            log_info(f"Removing temporary entitlements file: {temp_entitlements_path}")
            os.remove(temp_entitlements_path)

    # Remove quarantine attribute
    remove_quarantine_attribute(service_bin_path)


def check_dylib_exist(target_bin, dylib_name):
    """
    Check if the specified dylib is already injected into the binary.
    """
    log_info(f"Checking if {dylib_name} is already injected into: {target_bin}")
    try:
        result = run_cmd_ignore_output(f"otool -L '{target_bin}'")
        if dylib_name in result:
            log_warning(f"{dylib_name} is already injected into: {target_bin}")
            return True
    except RuntimeError as e:
        log_error(f"Failed to check dylib injection for {target_bin}: {str(e)}")
    return False


def handle_static_injection(app_name, app_bin_path, app):
    """
    Handle static injection for the app.
    """
    inject_param = app.get("inject_param", DEFAULT_INJECT_PARAM)
    inject_path = app.get("inject_path", app_bin_path)
    log_info(f"Injecting dylib into app binary (static): {inject_path}")
    log_info(f"Checking signature before re-signing for: {app.get('app_path')}")
    run_cmd_ignore_error(
        f"sudo codesign -d -vvv --entitlements - '{app.get('app_path')}'"
    )
    if not check_dylib_exist(inject_path, dylib_name):
        run_cmd_or_raise(
            f"sudo {insert_dylib} {inject_param} '@rpath/{dylib_name}' '{inject_path}'"
        )
    # Process services only for static type
    services = app.get("services", [])
    for service in services:
        process_service(service, app)


def handle_dynamic_injection(app_name):
    """
    Handle dynamic injection for the app.
    """
    log_info(f"Dynamic injection selected for app: {app_name}")
    # Add dynamic injection logic here if needed
    # Example: log_info("Dynamic injection is not implemented yet.")


def handle_process_injection(app_name):
    """
    Handle process-based injection for the app.
    """
    log_info(f"Process-based injection selected for app: {app_name}")
    # Add process-based injection logic here if needed
    # Example: log_info("Process-based injection is not implemented yet.")


def process_app(app):
    """
    Process a single app configuration.
    """
    app_name = app.get("app_name")
    app_path = app.get("app_path")
    app_bin_path = app.get("app_bin_path")
    re_sign_flag = app.get("re_sign", True)
    inject_type = app.get("inject_type", DEFAULT_INJECT_TYPE)
    app["app_framework_path"] = f"{app_path}/Contents/Frameworks"
    log_separator(app_name)

    if not os.path.exists(app_path):
        log_warning(f"❌ [{app_name}] not found at path: {app_path}. Skipping...")
        return

    try:
        version = run_cmd_silent(
            f"defaults read '{app_path}/Contents/Info.plist' CFBundleShortVersionString"
        )
        bundle_id = run_cmd_silent(
            f"defaults read '{app_path}/Contents/Info.plist' CFBundleIdentifier"
        )
    except Exception as e:
        log_warning(f"Failed to read app metadata for {app_name}: {str(e)}")
        version = "Unknown"
        bundle_id = "Unknown"

    user_input = "N"

    log_plain(
        f"✅ {GREEN}[{app_name} {version} {RED}({bundle_id}){RESET}{GREEN}] exists. Wanna inject? (Y/N): "
    )
    try:
        user_input = input().strip()
    except KeyboardInterrupt:
        log_plain("\n🛑 Operation canceled by user (Ctrl+C).")
        return
    except EOFError:
        log_plain("📭 End of input (Ctrl+D or closed input stream).")
        sys.exit(0)
        return

    if user_input.lower() != "y":
        log_info(f"😒 [{app_name}] skipped on user demand.")
        return
    log_info(f"Starting processing for app: {app_name}\r\n{json.dumps(app, indent=4)}")

    pre_script = app.get("pre_script")
    if app.get("pre_script", None):
        log_info(f"Running pre_script for app: {app_name} at {pre_script}")
        pre_script = app.get("pre_script")
        run_cmd_or_raise(f"sudo bash {pre_script}")

    # other_patches
    other_patches = app.get("other_patches", [])
    if other_patches:
        log_info(f"Applying other patches for app: {app_name}")
        for path in other_patches:
            call_mac_patch_helper(False, path, other_patches[path])

    app_bundle_framework = f"{app_path}/Contents/Frameworks/"
    os.makedirs(app_bundle_framework, exist_ok=True)
    log_info(f"Copying dylib to: {app_bundle_framework}")
    run_cmd_ignore_output(f'sudo cp -f "{release_dylib}" "{app_bundle_framework}"')

    app_re_sign_param = app.get("re_sign_param", DEFAULT_RE_SIGN_PARAM)
    app_re_sign_entitlements = app.get("re_sign_entitlements", False)
    app_re_sign_entitlements_path = app.get("re_sign_entitlements_path")
    app_temp_entitlements_path = None

    app_temp_entitlements_path = None
    if re_sign_flag and app_re_sign_entitlements:
        app_temp_entitlements_path = export_entitlements(
            app_path, app_re_sign_entitlements_path
        )
        app_re_sign_entitlements_path = app_temp_entitlements_path

    # Handle injection based on inject_type
    if inject_type == "static":
        log_warning(
            f"⚠️ Static injection is irreversible. Please back up your application at: {app_path}"
        )
        log_warning("Press any key to continue...")
        input()
        re_sign_flag = True  # Enable re-signing for static injection
        handle_static_injection(app_name, app_bin_path, app)
    elif inject_type == "dynamic":
        handle_dynamic_injection(app_name)
        re_sign_flag = False  # Disable re-signing for dynamic injection
    elif inject_type == "process":
        handle_process_injection(app_name)
        re_sign_flag = False  # Disable re-signing for process injection
    else:
        log_warning(f"Ignore inject_type '{inject_type}' for app: {app_name}")

    # Handle re-signing for the app
    if re_sign_flag:
        log_info(f"Re-signing app: {app_name}")
        re_codesign(
            app_path,
            app_re_sign_param,
            app_re_sign_entitlements,
            app_re_sign_entitlements_path,
        )
        if app_temp_entitlements_path:
            log_info(
                f"Removing temporary entitlements file: {app_temp_entitlements_path}"
            )
            os.remove(app_temp_entitlements_path)

    remove_quarantine_attribute(app_path)
    log_info(f"Finished processing for app: {app_name}")
    log_separator()


if __name__ == "__main__":
    try:
        # Scan and merge all apps.json files
        merge_apps_ori = load_and_merge_apps_json(current_dir)

        # Validate merged JSON data against the schema
        validate(instance=merge_apps_ori, schema=schema)

        init_hack()

        log_info("JSON validation successful!")

        # Resolve and replace variables
        apps = resolve_variables(merge_apps_ori)

        # Process each app
        for app in apps.get("apps", []):
            process_app(app)

    except ValidationError as e:
        log_error("JSON validation failed!")
        log_error(f"Error: {e.message}")
        log_error(f"Path: {'/'.join(map(str, e.path))}")
        log_error(f"Schema Path: {'/'.join(map(str, e.schema_path))}")
    except RuntimeError as e:
        log_error(f"Runtime error: {str(e)}")
    except Exception as e:
        log_error(f"Unexpected error: {str(e)}")
