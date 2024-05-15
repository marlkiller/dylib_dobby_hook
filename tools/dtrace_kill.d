#!/usr/sbin/dtrace -qs
/* sudo dtrace -s kill.d
 * kill.d - watch process signals as they are sent (eg, kill -9).
 *          Written in DTrace (Solaris 10 3/05).
 *
 * 16-Jun-2005, ver 1.00
 *
 * USAGE:       kill.d
 *
 * FIELDS:
 *              FROM     source PID
 *              COMMAND  source command name
 *              TO       destination PID
 *              SIG      destination signal ("9" for a kill -9)
 *              RESULT   result of signal (-1 is for failure)
 *
 * SEE ALSO: Chapter 25, Solaris Dynamic Tracing Guide, docs.sun.com,
 *           for a solution using proc:::signal-send.
 *
 * Standard Disclaimer: This is freeware, use at your own risk.
 *
 * 09-May-2004  Brendan Gregg   Created this.
 */
dtrace:::BEGIN
{
    /* Print header */
    printf("%5s %12s %5s %-6s %s\n","FROM","COMMAND","SIG","TO","RESULT");
}
syscall::kill:entry
{
    /* Record target PID and signal */
    self->target = arg0;
    self->signal = arg1;
}
syscall::kill:return
{
    /* Print source, target, and result */
    printf("%5d %12s %5d %-6d %d\n",
     pid,execname,self->signal,self->target,(int)arg0);
/* Cleanup memory */
    self->target = 0;
    self->signal = 0;
}
