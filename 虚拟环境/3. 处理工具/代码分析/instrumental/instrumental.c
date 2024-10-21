/*** (C) 2002-2006 Sebastian Krahmer.
 *** All rights reserved. You may use this software unter the GPL.
 ***
 *** See http://www.suse.de/~krahmer/instrumental for a PDF paper
 *** if you want to know what this code is doing. :-)
 ***
 *** gcc -finstrument-functions needs to be in CFLAGS of target,
 *** but not for this file (infinite recursion).
 ***/
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <elf.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/file.h>
#include <assert.h>


static int nsyms = 0;
static Elf32_Sym *elf32_syms = NULL;
static char *strtab = NULL;
static int depth = 0;
static char *logfile = "/tmp/log.inst.ascii";
static char *dotfile = "/tmp/log.inst.dot";
static FILE *logf = NULL;
static FILE *dotf = NULL;
static char *shstrtab = NULL;
static char *call_chain[4096];	/* should be more than enough */

int getresuid(uid_t *, uid_t *, uid_t *);


static int xread(int fd, void *buf, size_t len, const char *location)
{
	int r = read(fd, buf, len);

	if (r < 0) {
		fprintf(stderr, "%sread: %s ", location, strerror(errno));
		exit(errno);
	}
	if (r != len) {
		fprintf(stderr, "%sread: Invalid ELF32 file.\n", location);
		exit(errno);
	}
	return r;
}


/* Fill strtab and symtab, return #bytes read */
static int fill_tab(int fd, const Elf32_Shdr *shdr, char **result)
{
	int r;
	char *location = "instrumental::fill_tab::";
	off_t off;

	off = lseek(fd, 0, SEEK_CUR);

	if (off == (off_t)-1) {
		fprintf(stderr, "%slseek: %s\n", location, strerror(errno));
		exit(errno);
	}

	if (lseek(fd, shdr->sh_offset, SEEK_SET) == (off_t)-1) {
		fprintf(stderr, "%slseek: %s\n", location, strerror(errno));
		exit(errno);
	}

	/* free(NULL) is defined */
	free(*result);
	*result = (char*)malloc(shdr->sh_size);

	r = xread(fd, *result, shdr->sh_size, location);

	if ((off = lseek(fd, off, SEEK_SET)) != off) {
		fprintf(stderr, "%slseek: Nuts. Cannot seek back!\n", location);
		exit(errno);
	}
	return r;
}

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
	int fd, r, done = 0, n = 0;
	char buf[128], programname[1024];
	Elf32_Ehdr elf32_ehdr;
	Elf32_Shdr elf32_shdr;
	char *location = "instrumental::init::";
	int slen = 0;

	open_logs();

	memset(programname, 0, sizeof(programname));

	sprintf(buf, "/proc/%d/exe", getpid());
	if (readlink(buf, programname, sizeof(programname)) < 0) {
		fprintf(stderr, "%sreadlink: %s\n", location, strerror(errno));
		exit(errno);
	}

	if ((fd = open(programname, O_RDONLY)) < 0) {
		fprintf(stderr, "%sopen: %s\n", location, strerror(errno));
		exit(errno);
	}

	xread(fd, &elf32_ehdr, sizeof(elf32_ehdr), location);

	if (lseek(fd, elf32_ehdr.e_shoff+elf32_ehdr.e_shstrndx*elf32_ehdr.e_shentsize, SEEK_SET)
	    != elf32_ehdr.e_shoff+elf32_ehdr.e_shstrndx*elf32_ehdr.e_shentsize) {
		fprintf(stderr, "%slseek: %s\n", location, strerror(errno));
		exit(errno);
	}


	/* Get shstrtab */
	xread(fd, &elf32_shdr, sizeof(elf32_shdr), location);

	shstrtab = (char *)malloc(elf32_shdr.sh_size);
	if (lseek(fd, elf32_shdr.sh_offset, SEEK_SET) != elf32_shdr.sh_offset) {
		fprintf(stderr, "%slseek: %s\n", location, strerror(errno));
		exit(errno);
	}

	xread(fd, shstrtab, elf32_shdr.sh_size, location);

	if (lseek(fd, elf32_ehdr.e_shoff, SEEK_SET)
	    != elf32_ehdr.e_shoff) {
		fprintf(stderr, "%slseek: %s\n", location, strerror(errno));
		exit(errno);
	}

	/* Get strtab (need shstrtab to find it) and symtab */
	while (!done) {
		r = xread(fd, &elf32_shdr, sizeof(elf32_shdr), location);
		if (strcmp(&shstrtab[elf32_shdr.sh_name], ".strtab") == 0) { 
			slen = fill_tab(fd, &elf32_shdr, &strtab);
		}
		if (elf32_shdr.sh_type == SHT_SYMTAB) {
			r = fill_tab(fd, &elf32_shdr, (char**)&elf32_syms);
			nsyms = r/sizeof(Elf32_Sym);
		}
		++n;
		done = elf32_syms != NULL && strtab != NULL;
	}
	close(fd);
	call_chain[0] = strdup("root");

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
	uid_t uid, euid, ruid;
	char fname[1024];

	if (!nsyms)
		init();

	open_logs();

	flock(fileno(dotf), LOCK_EX);

	getresuid(&ruid, &euid, &uid);
	fprintf(logf, "~ [%04d|%04d|%04d] ", ruid, euid, uid);
	for (i = 0; i < depth; ++i)
		fprintf(logf, "  |");
	fprintf(logf, "--");

	/* Find function-symbol for address */
	for (i = 0; i < nsyms; ++i) {
		if (ELF32_ST_TYPE(elf32_syms[i].st_info) == STT_FUNC &&
		    elf32_syms[i].st_value == (Elf32_Addr)this_fn) {
			fprintf(logf, " %s (%p)\n",
			       &strtab[elf32_syms[i].st_name], this_fn);
			if (depth + 1 < sizeof(call_chain)/sizeof(call_chain[0]))
				call_chain[depth+1] = &strtab[elf32_syms[i].st_name];
		}
	}
#define USE_EUID
#ifdef USE_EUID
	snprintf(fname, sizeof(fname), "%s_%d", call_chain[depth+1], euid);
	call_chain[depth+1] = strdup(fname);
#endif

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

	if (euid == 0) {
		fprintf(dotf, "%s [color=red];\n", call_chain[depth+1]);
	} else {
		fprintf(dotf, "%s [color=grey];\n", call_chain[depth+1]);
	}

	fprintf(dotf, "%s->%s [weight=%u];\n", call_chain[depth],
	        call_chain[depth+1], depth);
	++depth;
	flock(fileno(dotf), LOCK_UN);
}


void __cyg_profile_func_exit(void *this_fn, void *call_site)
{
#ifdef USE_EUID
	free(call_chain[depth]);
#endif
	--depth;
}


