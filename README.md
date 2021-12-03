# Digital-System-Design-and-Synthesis

######### PID Control #########
![image](https://user-images.githubusercontent.com/71836374/144600866-494f1b63-708b-4b28-bf41-31262727ffea.png)


The TestBench is a self-checking one that instantiate the PID and declares a stimulus and resp memory to hold the 2000 vectors of stim & resp. Loops through the 2000 vectors and apply the stimulus vectors (starting with clk low) to the inputs as specified.
![image](https://user-images.githubusercontent.com/71836374/144600824-0ac8be34-de07-4097-92f2-376669ca2961.png)
![image](https://user-images.githubusercontent.com/71836374/144600841-94516bc1-ca85-40b9-84c7-444d17d89abd.png)

Post synthesis simulation:
FTPed the PID file into a CAE Linux Machine remotely through MobaXterm. Wrote a Synthesis script in dc_shell using Synopsys with the following constraints : 
![image](https://user-images.githubusercontent.com/71836374/144601531-a8b476be-dd83-47f8-9386-eb81b99caf3a.png)
![image](https://user-images.githubusercontent.com/71836374/144601556-2cb8fe84-eec5-4f10-a80f-26bc411084e4.png)
 Finally, I incorporated that gate level netlist generated from Synthesis, into my test bench (PID_tb.sv). 
