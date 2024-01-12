--get json
shell.run("pastebin get 4nRg9CHU json")
--get gitget
shell.run("pastebin get W5ZkVYSi gitget")
--use gitget to get repo
shell.run("gitget Quackers29 CC-Towns main")
--reboot
print("Rebooting...")
os.sleep(2)
os.reboot()