#include "result.h"
#include <stdio.h>
#include <stdlib.h>

static void getrusage_exit(int who, struct rusage *usage)
{
	int err;

	err = getrusage(who, usage);
	if (err) {
		perror("getrusage");
		exit(EXIT_FAILURE);
	}
}

static void subtv(struct timeval *diff, const struct timeval *a,
		  const struct timeval *b)
{
	diff->tv_sec = a->tv_sec - b->tv_sec;
	diff->tv_usec = a->tv_usec - b->tv_usec;
}

static void addtv(struct timeval *sum, const struct timeval *a,
		  const struct timeval *b)
{
	sum->tv_sec = a->tv_sec + b->tv_sec;
	sum->tv_usec = a->tv_usec + b->tv_usec;
}

static inline int fprinttv(const struct timeval *tv, FILE *stream)
{
	return fprintf(stream, "%f sec\n", tv->tv_sec + tv->tv_usec * 1e-6);
}

static void subru(struct rusage *diff, const struct rusage *a,
		  const struct rusage *b)
{
	subtv(&(diff->ru_utime), &(a->ru_utime), &(b->ru_utime));
	subtv(&(diff->ru_stime), &(a->ru_stime), &(b->ru_stime));
	diff->ru_maxrss = a->ru_maxrss - b->ru_maxrss;
	diff->ru_ixrss = a->ru_ixrss - b->ru_ixrss;
	diff->ru_idrss = a->ru_idrss - b->ru_idrss;
	diff->ru_isrss = a->ru_isrss - b->ru_isrss;
	diff->ru_minflt = a->ru_minflt - b->ru_minflt;
	diff->ru_majflt = a->ru_majflt - b->ru_majflt;
	diff->ru_nswap = a->ru_nswap - b->ru_nswap;
	diff->ru_inblock = a->ru_inblock - b->ru_inblock;
	diff->ru_oublock = a->ru_oublock - b->ru_oublock;
	diff->ru_msgsnd = a->ru_msgsnd - b->ru_msgsnd;
	diff->ru_msgrcv = a->ru_msgrcv - b->ru_msgrcv;
	diff->ru_nsignals = a->ru_nsignals - b->ru_nsignals;
	diff->ru_nvcsw = a->ru_nvcsw - b->ru_nvcsw;
	diff->ru_nivcsw = a->ru_nivcsw - b->ru_nivcsw;
}

static void addru(struct rusage *sum, const struct rusage *a,
		  const struct rusage *b)
{
	addtv(&(sum->ru_utime), &(a->ru_utime), &(b->ru_utime));
	addtv(&(sum->ru_stime), &(a->ru_stime), &(b->ru_stime));
	sum->ru_maxrss = a->ru_maxrss + b->ru_maxrss;
	sum->ru_ixrss = a->ru_ixrss + b->ru_ixrss;
	sum->ru_idrss = a->ru_idrss + b->ru_idrss;
	sum->ru_isrss = a->ru_isrss + b->ru_isrss;
	sum->ru_minflt = a->ru_minflt + b->ru_minflt;
	sum->ru_majflt = a->ru_majflt + b->ru_majflt;
	sum->ru_nswap = a->ru_nswap + b->ru_nswap;
	sum->ru_inblock = a->ru_inblock + b->ru_inblock;
	sum->ru_oublock = a->ru_oublock + b->ru_oublock;
	sum->ru_msgsnd = a->ru_msgsnd + b->ru_msgsnd;
	sum->ru_msgrcv = a->ru_msgrcv + b->ru_msgrcv;
	sum->ru_nsignals = a->ru_nsignals + b->ru_nsignals;
	sum->ru_nvcsw = a->ru_nvcsw + b->ru_nvcsw;
	sum->ru_nivcsw = a->ru_nivcsw + b->ru_nivcsw;
}

static void fprintru(const struct rusage *ru, FILE *stream)
{
	(void) fputs("user CPU time used: ", stream);
	(void) fprinttv(&(ru->ru_utime), stream);
	(void) fputs("system CPU time used: ", stream);
	(void) fprinttv(&(ru->ru_stime), stream);
	(void) fprintf(stream, "maximum resident set size: %ld\n"
			       "integral shared memory size: %ld\n"
			       "integral unshared data size: %ld\n"
			       "integral unshared stack size: %ld\n"
			       "page reclaims (soft page faults): %ld\n"
			       "page faults (hard page faults): %ld\n"
			       "swaps: %ld\n"
			       "block input operations: %ld\n"
			       "block output operations: %ld\n"
			       "IPC messages sent: %ld\n"
			       "IPC messages received: %ld\n"
			       "signals received: %ld\n"
			       "voluntary context switches: %ld\n"
			       "involuntary context switches: %ld\n",
		       ru->ru_maxrss, ru->ru_ixrss, ru->ru_idrss, ru->ru_isrss,
		       ru->ru_minflt, ru->ru_majflt, ru->ru_nswap,
		       ru->ru_inblock, ru->ru_oublock, ru->ru_msgsnd,
		       ru->ru_msgrcv, ru->ru_nsignals, ru->ru_nvcsw,
		       ru->ru_nivcsw);
}

void getresbef(struct result *res)
{
	getrusage_exit(RUSAGE_SELF, &(res->ru));
	res->time = realtime();
}

void getresaft(struct result *res)
{
	res->time = realtime();
	getrusage_exit(RUSAGE_SELF, &(res->ru));
}

void subres(struct result *diff, const struct result *a,
	    const struct result *b)
{
	diff->time = a->time - b->time;
	subru(&(diff->ru), &(a->ru), &(b->ru));
}

void addres(struct result *sum, const struct result *a, const struct result *b)
{
	sum->time = a->time + b->time;
	addru(&(sum->ru), &(a->ru), &(b->ru));
}

void subincres(struct result *res, const struct result *a,
	       const struct result *b)
{
	struct result diff;
	subres(&diff, a, b);
	incres(res, &diff);
}

void fprintres(const struct result *res, FILE *stream)
{
	(void) fprintf(stream, "time: %f\n", res->time);
	fprintru(&(res->ru), stream);
}
