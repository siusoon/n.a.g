nag_Bash is written in a Bash script, developed in 1989, which is a piece of free software with the type of Unix Shell for GNU platforms. The shell script nag_Bash.sh is a plain text file that contains a series of command.

• 1st line: `#!` is often referred to as “hashbang” or “shebang”. It points to the specific path of the shell program (Bash interpreter) to execute the bash script.
• 2nd line: Declare the variable (`site`) and store the nag’s URL.
• 3rd line: Specify the request of images, including the parameters of action (ac), query type (query), number of composition (comp), width and file type extension (ext). This line also sends the specified data in an (HTTP) post request to the nag server and returns the result (`request`). 
• 4th line: Parse the content from the result (`request`) and look for the path of the newly generated collage in the jpg file format. This requires the matching pattern of the folder name (gen) and the file name (anonymous-warhol_flowers).
• 5th line: Retrieve and save the identified image file.

The script automatically runs every day at Hong Kong time 15.00 / Hamburg time 09.00 / California time 00.00 with the cron job set up on the server for scheduling daily tasks repeatedly:  `0 15 * * * /usr/bin/bash path/nag_Bash.sh`
