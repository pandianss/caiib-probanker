import sys

file_path = sys.argv[1]
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace single backslash with double backslash
# but avoid doubling already doubled ones if any (though here we want total escaping)
# The safest way for JSON is to just escape every backslash that isn't part of a valid escape like \n, \", etc.
# But for math, we just want to escape every \.
fixed_content = content.replace('\\', '\\\\')

# However, we might have already used \n or \".
# Let's be smarter: replace all backslashes, then fix the double-escaped newlines.
fixed_content = fixed_content.replace('\\\\n', '\\n').replace('\\\\"', '\\"')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(fixed_content)
