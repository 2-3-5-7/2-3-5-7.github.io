/*** (C) 2002-2006 Sebastian Krahmer.
 *** All rights reserved. You may use this software unter the GPL.
 ***
 *** See http://www.suse.de/~krahmer/instrumental for a PDF paper
 *** if you want to know what this code is doing. :-)
 ***
 *** gcc -finstrument-functions needs to be in CFLAGS of target,
 *** but not for this file (infinite recursion).
 ***/
#define _GNU_SOURCE
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/file.h>
#include <assert.h>
#include <dlfcn.h>

static int depth = 0;
static char *logfile = "/tmp/log.inst.ascii";
static char *dotfile = "/tmp/log.inst.dot";
static FILE *logf = NULL;
static FILE *dotf = NULL;
static const char *call_chain[4096];	/* should be more than enough */

int getresuid(uid_t *, uid_t *, uid_t *);

static void open_logs()
{
	char d[128], l[128];
	char *location = "instrumental::open_logs::";

	if (logf && dotf) {	
		/* If files are already opened, skip it */
		if (fcntl(fileno(logf), F_GETFD) != -1 &&
		    fcntl(fileno(dotf), F_GETFD) != -1)
			return;
	}

	if (logf)
		fclose(logf);
	if (dotf)
		fclose(dotf);
	logf = NULL; dotf = NULL;

	assert(logfile && dotfile);

	snprintf(l, sizeof(l), "%s.%d", logfile, getpid());
	if ((logf = fopen(l, "a")) == NULL) {
		fprintf(stderr, "%sfopen: %s", location, strerror(errno));
		exit(errno);
	}
	snprintf(d, sizeof(d), "%s.%d", dotfile, getpid());
	if ((dotf = fopen(d, "a")) == NULL) {
		fprintf(stderr, "%sfopen: %s", location, strerror(errno));
		exit(errno);
	}
	
	setbuffer(logf, NULL, 0);
	setbuffer(dotf, NULL, 0);
}

static void init()
{
	open_logs();
	call_chain[0] = "root";

	fprintf(dotf, "digraph G {\n"
	           "size=\"7,9\";concentrate=true;\nrankdir=LR;\nratio=fill;\n"
	           "node [shape=box,style=filled,fontsize=8];\n");
}

/* WIll be called upon every function-entry of own written
 * function.
 */
void __cyg_profile_func_enter(void *this_fn, void *call_site)
{
	int i = 0;
	char fname[1024];
	Dl_info info;

	if (!depth)
		init();

	open_logs();

	flock(fileno(dotf), LOCK_EX);

	/*
	uid_t uid, euid, ruid;
	getresuid(&ruid, &euid, &uid);
	fprintf(logf, "~ [%04d|%04d|%04d] ", ruid, euid, uid);
	*/

	for (i = 0; i < depth; ++i)
		fprintf(logf, "  |");
	fprintf(logf, "--");

	/* Find function-symbol for address */
	if (!dladdr(this_fn, &info)) {
		fprintf(stderr, "dladdr: can't get func %p name\n", this_fn);
		exit(1);
	}

	if (info.dli_sname)
		snprintf(fname, sizeof(fname), "%s", info.dli_sname);
	else
		snprintf(fname, sizeof(fname), "%p", this_fn);

	fprintf(logf, " %s\n", fname);
	if (depth + 1 < sizeof(call_chain)/sizeof(call_chain[0]))
		call_chain[depth+1] = strdup(fname);

	switch (depth % 8) {
	case 0:
		fprintf(dotf, "edge [color=grey];\n");
		break;
	case 1:
		fprintf(dotf, "edge [color=blue];\n");
		break;
	case 2:
		fprintf(dotf, "edge [color=red];\n");
		break;
	case 3:
		fprintf(dotf, "edge [color=green];\n");
		break;
	case 4:
		fprintf(dotf, "edge [color=yellow];\n");
		break;
	case 5:
		fprintf(dotf, "edge [color=pink];\n");
		break;
	case 6: 
		fprintf(dotf, "edge [color=black];\n");
		break;
	case 7:
		fprintf(dotf, "edge [color=orange];\n");
		break;
	}

	fprintf(dotf, "\"%s\" [color=grey];\n", call_chain[depth+1]);
	fprintf(dotf, "\"%s\"->\"%s\" [weight=%u];\n", call_chain[depth],
	        call_chain[depth+1], depth);
	++depth;
	flock(fileno(dotf), LOCK_UN);
}

void __cyg_profile_func_exit(void *this_fn, void *call_site)
{
	free((void *)call_chain[depth]);
	--depth;
}


