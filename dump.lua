local contents = string.dump(phileos.tokenize)
term.print(contents)
fs.write("/apis/phileos.lua", contents)
phileos.sleep(10)