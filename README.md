# Instructions for use smoothie board controller

----

**MINI-CNC ENGRAVING MACHUNES**

Revision History
2017-10-23 *version0.1*

---

### Introduce interface  

![](/Users/angqinghua/Desktop/smoothie board instruction/WechatIMG10.jpeg)

![](/Users/angqinghua/Desktop/smoothie board instruction/WX20171023-111800@2x.png
)  

![](/Users/angqinghua/Desktop/smoothie board instruction/WX20171023-112318@2x.png
)

---

### Connect smoothie board
1. Open smoothie board uart(boudrate:115200).  
	 If log text view show smoothie board `Build version`,It's working.
2. Choose work model `relative` or `absoulte`
3. Make sure to stop at the origin before turning on the power.  
	If you do not want the original point, turn off the power and then manually adjust
4. `Limit textfield` you can enter each move distance.
	
	
---

### Notes
1. Turn off the power included POWER button and USB power。
2. Do not exceed the XYZ movement range or you must reset origin.
3. Z direction as far as possible to manually adjust.

---

### Postscript
Thanks to [ORSSerialPort](https://github.com/armadsen/ORSSerialPort)

