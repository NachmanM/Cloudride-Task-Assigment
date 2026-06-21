import os

src_file_path = "../terraform/task-definitions/nginx-docker-template.json"
dest_file_path = "../terraform/task-definitions/nginx-docker.json"

resource_name = os.getenv("resource_name")
repo_url = os.getenv("repo_url")
cloudwatch_log_group = os.getenv("cloudwatch_log_group")
region = os.getenv("region")
image_tag = os.getenv("image_tag")

load_vars = {
    r"{{ resource_name }}": resource_name,
    r"{{ name }}": "hello-world-nachman",
    r"{{ repo_url }}": repo_url,
    r"{{ cloudwatch_log_group }}": cloudwatch_log_group,
    r"{{ region }}": region,
    r"{{ image_tag }}": image_tag
}

with open(src_file_path, "r", encoding="utf-8") as file:
    content = file.read()

for k, v in load_vars.items():
    content = content.replace(k, v)

with open(dest_file_path, "w", encoding="utf-8") as file:
    file.write(content)