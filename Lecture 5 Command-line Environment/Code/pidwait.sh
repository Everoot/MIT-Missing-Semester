pidwait()
{
	while kill -0 $1 # loop until process finish
	do 
		sleep 1
	done 
	ls
}
