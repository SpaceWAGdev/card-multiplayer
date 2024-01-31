from git import Repo
import time
from colorama import Fore, Back, Style

REPLACEMENTS = {"starlight_caffeine": "Liam Stedman", "arthorias561": "Noah Büchold"}

repo = Repo(".")
commits = repo.iter_commits()

for commit in commits:
    print(time.strftime("%A %d.%m.%Y", time.localtime(commit.committed_date)))
    author_name = commit.author.name
    for r in REPLACEMENTS.keys():
        author_name = author_name.replace(r, REPLACEMENTS[r])
    print(f"{author_name} {Fore.YELLOW} <{commit.author.email}>{Style.RESET_ALL}")
