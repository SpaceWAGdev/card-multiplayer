#!/bin/env python3
import git, json, time, sys, os
return_lines = []
repo = git.Repo("../")
commits = repo.iter_commits()
all_commits = False

if len(sys.argv) > 1 and sys.argv[1] == "--all":
    all_commits = True

for commit in commits:
    if commit.committed_date < (int(time.time()) - 604800) and not all_commits:
        continue

    return_lines.append({
        "author_username": commit.author.name,
        "author_email": commit.author.email,
        "datetime": commit.committed_date,
        "hexsha": commit.hexsha,
        "commit_message": commit.message.strip(),
        "changes": commit.stats.total
    })

with open("commits.json", "w") as f:
    json.dump(return_lines, f)

os.system(f"typst compile report.typ")