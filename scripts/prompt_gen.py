import os
import argparse
import pyperclip
from pathlib import Path
from fire import Fire
import json


def generate_file_tree(startpath):
    lines = ["Project Structure:"]

    startpath = os.path.abspath(startpath)
    skip_names = {".git", ".vscode", ".godot", "addons", "scripts"}

    def iter_entries(path):
        entries = []
        with os.scandir(path) as it:
            for entry in it:
                if entry.is_dir():
                    if entry.name in skip_names:
                        continue
                    entries.append(entry)
                elif entry.is_file() and entry.name.endswith((".tscn", ".gd", ".json")):
                    entries.append(entry)

        entries.sort(key=lambda e: (not e.is_dir(), e.name.lower()))
        return entries

    def walk(path, prefix):
        entries = iter_entries(path)
        for index, entry in enumerate(entries):
            is_last = index == len(entries) - 1
            branch = "└── " if is_last else "├── "
            suffix = "/" if entry.is_dir() else ""
            lines.append(f"{prefix}{branch}{entry.name}{suffix}")
            if entry.is_dir():
                next_prefix = prefix + ("    " if is_last else "│   ")
                walk(entry.path, next_prefix)

    walk(startpath, "")
    return "\n".join(lines) + "\n"


def format_prompt(file_paths, task_description=""):
    prompt = []

    # 1. 添加系统级指令
    prompt.append("I am providing you with the context of a godot card stask game.")
    prompt.append(
        "Below is the file structure and the content of selected source files.\n"
    )

    # 2. 添加文件树 (帮助模型理解引用关系)
    prompt.append(generate_file_tree("."))
    prompt.append("\n---\n")

    # 3. 遍历文件并使用 XML 格式包裹
    prompt.append("<code_context>")
    for file_path in file_paths:
        path_obj = Path(file_path)
        if not path_obj.exists():
            print(f"Warning: {file_path} not found.")
            continue

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            # 使用 XML 标签清晰分隔每个文件
            prompt.append(f'<document path="{file_path}">')
            prompt.append(content)
            prompt.append("</document>\n")
        except Exception as e:
            print(f"Error reading {file_path}: {e}")

    prompt.append("</code_context>\n")

    # 4. 预留任务位置
    prompt.append("Based on the context above, please perform the following task:")
    if task_description:
        prompt.append(task_description)
    else:
        prompt.append("[USER TASK HERE]")

    return "\n".join(prompt)


def main():
    parser = argparse.ArgumentParser(description="Pack repo files for LLM prompting.")
    parser.add_argument(
        "files",
        nargs="+",
        help="List of files to include (supports glob if shell expands it)",
    )
    parser.add_argument("--task", "-t", help="Specific task instructions", default="")
    args = parser.parse_args()

    # 生成最终 Prompt
    full_prompt = format_prompt(args.files, args.task)

    # 自动复制
    try:
        pyperclip.copy(full_prompt)
        print(f"✅ Success! {len(full_prompt)} chars copied to clipboard.")
        print("Structure: File Tree -> <code_context> -> Task")
    except Exception as e:
        print(f"Generated text (copy failed: {e}):\n{full_prompt}")


def pg(task_file):
    # 从task_file.json中读取上下文文件，以及任务描述
    file_path = Path("scripts") / (task_file + ".json")
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    file_list = data.get("files", [])
    task_desc = data.get("task", "")

    full_prompt = format_prompt(file_list, task_desc)
    try:
        pyperclip.copy(full_prompt)
        print(f"✅ Success! {len(full_prompt)} chars copied to clipboard.")
    except Exception as e:
        print(f"Generated text (copy failed: {e}):\n{full_prompt}")
    pass


if __name__ == "__main__":
    Fire(pg)
