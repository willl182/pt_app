import os

target_dir = "/home/w182/w421/pt_app/Entregables_pt_app"

for root, dirs, files in os.walk(target_dir):
    for file in files:
        if file.endswith(('.R', '.md', '.mmd')):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            # Perform replacements
            new_content = content.replace("deliv/", "Entregables_pt_app/")
            new_content = new_content.replace('== "deliv"', '== "Entregables_pt_app"')
            new_content = new_content.replace("== 'deliv'", "== 'Entregables_pt_app'")
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated: {file_path}")

print("Path replacement completed.")
