# Instructions for smoothie board controller

----

**MINI-CNC ENGRAVING MACHUNES**

Revision History  
2017-10-23 *version0.1*  

2017-10-26 *version0.2*  

---

### Introduce interface  


......

---

### smoothie board controller useage

1. Open smoothie board uart(boudrate:`115200`).  
	 If `log text view` show smoothie board `Build version`,It's working.
2. Choose work model `relative` or `absoulte`.
3. Each time the smoothie board is reboot, it set the current position as origin `(X:0 Y:0 Z:0)`. Make sure to stop return the robot back to the origin before turning off the power.  
4. If you wish to set a **new orgin point**.  
	* 	Turn off all the power for smootie board and then manually adjust it.  
	*  Move to the position you want，then send `G92`. 
5. `Distance textfield` you can enter each move distance.
	
---

### Notes
1. Turn off the power included POWER button and USB power.
2. Do not exceed the XYZ movement range or you must reset origin.
3. Z direction as far as possible to manually adjust for short distance.

---

### Postscript
G-Code [instructions](http://reprap.org/wiki/G-code)  
Thanks to [ORSSerialPort](https://github.com/armadsen/ORSSerialPort)


![GitHub License Badge](https://img.shields.io/badge/license-MIT-blue.svg)




