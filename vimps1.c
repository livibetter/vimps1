/********************************************************************************/
/* Bash loadable builtin for PS1 with color and Vim-like directory abbreviation */
/*                                                                              */
/* Copyright (c) 2011-2015, 2017 Yu-Jie Lin                                     */
/*                                                                              */
/* Permission is hereby granted, free of charge, to any person obtaining a copy */
/* of this software and associated documentation files (the "Software"), to     */
/* deal in the Software without restriction, including without limitation the   */
/* rights to use, copy, modify, merge, publish, distribute, sublicense, and/or  */
/* sell copies of the Software, and to permit persons to whom the Software is   */
/* furnished to do so, subject to the following conditions:                     */
/*                                                                              */
/* The above copyright notice and this permission notice shall be included in   */
/* all copies or substantial portions of the Software.                          */
/*                                                                              */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  */
/* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING      */
/* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS */
/* IN THE SOFTWARE.                                                             */
/********************************************************************************/

#include <config.h>

#if defined (HAVE_UNISTD_H)
#include <unistd.h>
#endif

#include <stdbool.h>
#include <stdio.h>

#include "builtins.h"
#include "shell.h"

// \\[ and \\] don't work
#define _PROMPT_START_IGNORE "\001\001"
#define _PROMPT_END_IGNORE   "\001\002"
#define CF _PROMPT_START_IGNORE "\033[1;%dm" _PROMPT_END_IGNORE
#define RS _PROMPT_START_IGNORE "\033[0m"    _PROMPT_END_IGNORE

#define MAXCOL 4
#define COLOR_DIR  32
#define COLOR_HOME 35
#define COLOR_SEP  31
#define COLOR_ABBR 37

int
vimps1_builtin (WORD_LIST *list)
{
  if (list && *list->word->word != '0')
  {
    int columns = atoi(get_string_value("COLUMNS"));
    size_t pad_len = (columns - strlen(list->word->word)) / 2;
    printf("\033[41;1;37m%*s", columns, "");
    printf("\033[%zuG%s\033[0m\n" RS, pad_len, list->word->word);
  }

  if (!current_user.user_name)
  {
    get_current_user_info();
  }

  const char *pwd = get_string_value("PWD");
  printf(" ");
  if (strstr(pwd, current_user.home_dir) == pwd)
  {
    printf(CF "~", COLOR_HOME);
    pwd += strlen(current_user.home_dir);
  }

  while (pwd && *pwd++)
  {
    char *p = strstr(pwd, "/");
    bool last = p == NULL;
    char *chdir = strndup(pwd, (last ? strlen(pwd) : (size_t) (p - pwd)));
    size_t wclen = mbstowcs(NULL, chdir, 0) + 1;
    wchar_t *wcdir = malloc(sizeof(wchar_t) * wclen);
    mbstowcs(wcdir, chdir, wclen);
    free(chdir);

    for (wchar_t *pp = wcdir; *pp; pp++)
    {
      if (iswcntrl(*pp))
      {
        *pp = L'?';
      }
    }

    int color = COLOR_DIR;
    if (!last && wcswidth(wcdir, wclen) > MAXCOL)
    {
      wclen = 0;
      while (wcswidth(wcdir, ++wclen) <= MAXCOL);
      wcdir[wclen - 1] = L'\0';
      color = COLOR_ABBR;
    }

    printf(CF "/" CF "%ls", COLOR_SEP, color, wcdir);
    free(wcdir);
    pwd = p;
  }

  // user prompt char and color, root has red #, otherwise green $
  const bool USER = current_user.uid > 0;
  printf(" " CF "%c" RS " ", 31 + 3 * USER, '#' + USER);

  return (EXECUTION_SUCCESS);
}

char *vimps1_doc[] =
{
  "Vim-like directory abbreviation PS1.",
  "",
  "Multi-color and Vim-like directory abbreviation",
  (char *) NULL
};

struct builtin vimps1_struct =
{
  "vimps1",
  vimps1_builtin,
  BUILTIN_ENABLED,
  vimps1_doc,
  "vimps1",
  0
};
