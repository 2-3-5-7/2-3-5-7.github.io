from pynput import keyboard
import pyautogui, sys, os
import time
from datetime import datetime,timedelta

# pip install pynput PyAutoGUI

# 几次翻页键，第几节开始是下一页
pgdn_times = 8
npg_ke = 2
# 添加课程时间
ket = [
# 先不挂下面
#'00:04:46',
# 9
'00:41:49',
# 可以多一行写已挂时长
'04:08:39',
]
# 等待进入课程的时间
waitload = 15
# 返回课程
retx = 160
rety = 136
# 防挂机
gjx = 691
gjy = 576

# 课程列表坐标
key = []
kex = []

finish_input = 0
gj_pause = 0
ptsec = 0
gj_sumsec = 0

def sum_time():
    sum = 0
    for i in range(len(ket)):
        pt = ket[i].split(":", 2)
        sum = sum + int(pt[0]) * 3600 + int(pt[1]) * 60 + int(pt[2])
    if sum < 6 * 60 * 60:
        remain = 6 * 60 * 60 - sum
    else:
        remain = 0
        
    pt = ket[len(ket) - 1].split(":", 2)
    sum_ex = sum - int(pt[0]) * 3600 - int(pt[1]) * 60 - int(pt[2])
    sum_ex = sum_ex + (len(ket) - 1) * 60 + sum_ex / 60 * 4
    fin = (datetime.now() + timedelta(seconds = sum_ex)).strftime('%H:%M:%S')
    print('%d 节总时长 %02d:%02d:%02d，预计 %s 完成\n总挂机 %02d:%02d:%02d，还可挂 %d 分钟' % (len(ket) - 1, sum_ex / 3600, sum_ex % 3600 / 60, sum_ex % 60, fin
    , sum / 3600, sum % 3600 / 60, sum % 60, remain / 60))

def on_activate_a():
    global finish_input
    global gj_pause
    global ptsec
    global npg_ke
    if finish_input == 0:
        x, y = pyautogui.position()
        kex.append(x)
        key.append(y)
        if len(kex) == npg_ke:
            print('翻页次数：%d' % (pgdn_times + 1))
        elif len(kex) == 1:
            print('翻页次数：%d' % (pgdn_times))
        positionStr = '课程 ' + str(len(kex)) + ' (' + str(x) + ', ' + str(y) + '), 时长 ' + ket[len(kex) - 1]
        print(positionStr)
    else:
        if gj_pause == 0:
            gj_pause = 1
            print('挂机暂停，已挂 %02d:%02d:%02d，本节剩余 %02d:%02d' % 
                (gj_sumsec / 3600, gj_sumsec % 3600 / 60, gj_sumsec % 60, int(ptsec) / 60, int(ptsec) % 60))
            print('请同时将视频手动暂停。恢复时，请先手动恢复播放')
        else:
            gj_pause = 0
            print('挂机恢复，请确保视频已恢复播放')

def on_activate_q():
    global finish_input
    if finish_input == 0:
        print('')
        finish_input = 1
    else:
        print('挂机停止，已挂 %02d:%02d:%02d，本节剩余 %02d:%02d' % 
                (gj_sumsec / 3600, gj_sumsec % 3600 / 60, gj_sumsec % 60, int(ptsec) / 60, int(ptsec) % 60))
        os._exit(1)

sum_time()
h = keyboard.GlobalHotKeys({
        '<ctrl>+<alt>+a': on_activate_a,
        '<ctrl>+<alt>+q': on_activate_q})
h.start()

while finish_input != 1:
    pass

for i in range(len(kex)):
    # 进入课程开始播放
    print('进入课程 ' + str(i + 1) + ', 时长 ' + ket[i])
    
    pyautogui.click(x=gjx, y=gjy)
    time.sleep(1)
    for x in range(0, pgdn_times):
        pyautogui.press('pgdn')
        time.sleep(2)
    if i + 1 >= npg_ke:
        pyautogui.press('pgdn')
        time.sleep(2)
        
    pyautogui.click(x=kex[i], y=key[i])
    time.sleep(waitload)
    pyautogui.click(x=gjx, y=gjy)
    
    # 防挂机点击
    pt = ket[i].split(":", 2)
    ptsec = int(pt[0]) * 3600 + int(pt[1]) * 60 + int(pt[2])
    ptsec = ptsec + ptsec / 60 * 3
    print('开始挂机 ' + str(int(ptsec)) + ' 秒')
    while ptsec > 0:
        while gj_pause == 1:
            pass
        ptsec = ptsec - 1
        gj_sumsec = gj_sumsec + 1
        time.sleep(1)
        pyautogui.click(x=gjx, y=gjy)
        
    # 返回课程
    print('从课程 ' + str(i + 1) + ' 返回\n')
    pyautogui.click(x=retx, y=rety)
    time.sleep(15)
    