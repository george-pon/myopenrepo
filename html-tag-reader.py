#
# html タグを処理する
#
# 2024/12/21
#

filename_in = "hoge.html"
filename_out = "hoge_new.html"

with open(filename_in, mode='r', encoding='UTF-8', newline="\n") as file:
    lines = file.readlines()

# pass 1 分割されたinputタグは１行にまとめる
outlines = []
outline = ""
is_intag = False
for line in lines:

    if is_intag:
        outline += line
        if '>' in line:
            is_intag = False
            print("leave in tag mode")
            outlines.append(outline)
            outline = ""
        continue

    idx1 = line.find('<input', 0)
    if idx1 >= 0:
        idx2 = line.find('>', idx1)
        if idx2 < 0:
            is_intag = True
            print("enter in tag mode")
            outline += line
            continue

    outlines.append(line)

# end of for

lines = outlines

outlines = []
for i, line in enumerate(lines):
    print(f"{i}:{line}")
    outlines.append(line)

with open(filename_out, mode='w', encoding="utf-8", newline="\n") as file2:
    file2.writelines(lines)
