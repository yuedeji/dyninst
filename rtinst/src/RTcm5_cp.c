/*
 * This file contains the implementation of runtime dynamic instrumentation
 *   functions for a normal Sparc with SUNOS.
 *
 * $Log: RTcm5_cp.c,v $
 * Revision 1.2  1993/07/02 21:53:33  hollings
 * removed unnecessary include files
 *
 * Revision 1.1  1993/07/02  21:49:35  hollings
 * Initial revision
 *
 *
 */
#include <stdio.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/param.h>

#include <cm/cmmd/amx.h>
#include <cm/cmmd/mp.h>
#include <cm/cmmd/cn.h>
#include <cm/cmmd/io.h>
#include <cm/cmmd/util.h>
#include <cm/cmmd/cmmd_constants.h>
#include <cm/cmmd.h>
#include <cm/cmna.h>

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stdtypes.h>
#include <sys/time.h>
#include <sys/timeb.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/vfs.h>
#include <cm/cm_file.h>
#include <cm/cm_errno.h>
#include <errno.h>
#include <sys/un.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <sys/filio.h>
#include <math.h>

#include "rtinst.h"
#include "trace.h"

/*
 * Generate a fork record for each node in the partition.
 *
 */
DYNINSTnodeCreate()
{
    int i;
    int sid = 0;
    traceFork forkRec;
    extern int CMNA_partition_size;

    forkRec.ppid = getpid();
    if (CMNA_partition_size <= 0) {
	perror("Error in CMMD_partition_size");
    }
    forkRec.pid = forkRec.ppid + MAXPID;
    forkRec.npids = CMNA_partition_size;
    forkRec.stride = MAXPID;
    DYNINSTgenerateTraceRecord(sid, TR_MULTI_FORK, sizeof(forkRec), &forkRec);
}

void DYNINSTparallelInit()
{
    printf("calling initTraceLibCP\n");
    initTraceLibCP(CONTROLLER_FD);
}

