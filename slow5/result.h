#ifndef RESULT_H
#define RESULT_H

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <sys/resource.h>
#include <sys/time.h>
#include <stdio.h>

struct result {
	double time;
	struct rusage ru;
};

void getresbef(struct result *res);
void getresaft(struct result *res);
void subres(struct result *diff, const struct result *a,
	    const struct result *b);
void addres(struct result *sum, const struct result *a, const struct result *b);
static inline void incres(struct result *res, const struct result *a)
{
	addres(res, res, a);
}
void subincres(struct result *res, const struct result *a,
	       const struct result *b);
void fprintres(const struct result *res, FILE *stream);

static inline double realtime(void) {
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp, &tzp);
    return tp.tv_sec + tp.tv_usec * 1e-6;
}

// From minimap2
static inline long peakrss(void) {
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);
#ifdef __linux__
    return r.ru_maxrss * 1024;
#else
    return r.ru_maxrss;
#endif
}

// From minimap2/misc
static inline double cputime(void) {
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);
    return r.ru_utime.tv_sec + r.ru_stime.tv_sec +
           1e-6 * (r.ru_utime.tv_usec + r.ru_stime.tv_usec);
}

#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* result.h */
