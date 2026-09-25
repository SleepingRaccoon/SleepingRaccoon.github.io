---
title: 大斜视角下的距离多普勒算法
order: 14
description: 与小斜视角那篇对照着看：瞬时斜距全程保留双曲形式，走完距离向 FFT、方位向二维频谱、距离向 IFFT、二次距离压缩与方位压缩，并比较 SRC 的三种实现方式。
---

## 1 符号约定
先把符号列清楚，后面直接引用。与《[小斜视角下的距离多普勒算法](/radar/10_RDA_小斜视角/)》的唯一区别在第 4 条：瞬时斜距保留双曲形式，不做抛物线近似。
*   $\tau$：**距离向快时间**。
*   $\eta$：**方位向慢时间**。
*   $\eta_c$：**波束中心穿越时刻**；$\eta = 0$ 是零多普勒时刻（最近斜距 $R_0$ 的时刻）。
*   $R(\eta) = \sqrt{R_0^2 + V_r^2 \eta^2}$：**瞬时斜距**（双曲模型，本文全程不近似）。
*   $R_0$：**最近斜距**；$V_r$：雷达相对地面的等效速度。
*   $f_0$：载频，$\lambda = c/f_0$；$c$：光速。
*   $K_r$：距离向调频率；$T_r$：脉冲宽度；$B_r = \lvert K_r \rvert  T_r$：发射带宽。
*   $w_r(\cdot), w_a(\cdot)$：距离向、方位向时域包络；$W_r(f_\tau), W_a(f_\eta)$：对应的频域包络。
*   $f_\tau, f_\eta$：距离频率、方位频率（多普勒频率）；$f_{\eta c}$：多普勒中心频率。
*   $A_0, A_1, A_2$：复常数。POSP 带来的幅度因子与 $\pm \pi/4$ 相位都与 $\tau,\eta$ 无关，一律并进这些常数。
*   $D_{2df}(f_\tau, f_\eta, V_r) = \sqrt{1 - \dfrac{c^2 f_\eta^2}{4 V_r^2 (f_0 + f_\tau)^2}}$：**二维频域徙动因子**。
*   $D(f_\eta, V_r)$：**距离多普勒域徙动因子**，也就是 $D_{2df}(f_\tau, f_\eta, V_r)$ 在 $f_\tau = 0$ 处取的值，几何上等于瞬时斜视角的余弦：

$$
     D(f_\eta, V_r) = \sqrt{1 - \dfrac{c^2 f_\eta^2}{4 V_r^2 f_0^2}}
$$

*   $Z(R_0, f_\eta)$：推导中引入的中间量，见式(20)。
*   $K_m$：距离多普勒域里的**等效距离调频率**，见式(26)；$K_{src}$：**二次距离压缩（SRC）调频率**。

与小斜视角的关键差别：载频相位里出现的是 $f_0 + f_\tau$ 而不是单独的 $f_0$，距离频率和方位频率就会自然地乘在一起，这就是**距离-方位交叉耦合**。后面每一步都在处理它。对照推导见《[小斜视角下的距离多普勒算法](/radar/10_RDA_小斜视角/)》。

## 2 距离向 FFT
接收解调后的基带信号为

$$
 s_0(\tau, \eta) = A_0 w_r\left[\tau - \frac{2R(\eta)}{c}\right] w_a(\eta - \eta_c) \exp\left\{-j \frac{4\pi f_0 R(\eta)}{c}\right\} \exp\left\{j \pi K_r \left(\tau - \frac{2R(\eta)}{c}\right)^2\right\} \tag{1}
$$

对 $\tau$ 做 FFT，需要计算积分 $\int s_0(\tau,\eta)\exp\lbrace -j 2\pi f_\tau \tau\rbrace  d\tau$。注意 $R(\eta)$ 与 $\tau$ 无关，总相位为

$$
 \Theta(\tau) = -\frac{4\pi f_0 R(\eta)}{c} + \pi K_r \left[\tau - \frac{2R(\eta)}{c}\right]^2 - 2\pi f_\tau \tau \tag{2}
$$

求导并令导数为零：

$$
 \frac{d\Theta(\tau)}{d\tau} = 2\pi K_r \left[\tau - \frac{2R(\eta)}{c}\right] - 2\pi f_\tau = 0 \tag{3}
$$

解得驻定点：

$$
 \tau^* = \frac{f_\tau}{K_r} + \frac{2R(\eta)}{c} \tag{4}
$$

二阶导 $\Theta^{\prime\prime}= 2\pi K_r$ 是常数，把式(4)代回式(2)：

$$
 \Theta(\tau^*) = -\frac{4\pi f_0 R(\eta)}{c} - \frac{\pi f_\tau^2}{K_r} - \frac{4\pi f_\tau R(\eta)}{c}
 = -\frac{4\pi (f_0 + f_\tau) R(\eta)}{c} - \frac{\pi f_\tau^2}{K_r} \tag{5}
$$

距离窗在驻点处取值，记它的频谱为 $W_r(f_\tau)$，于是距离频域信号为

$$
 S_0(f_\tau, \eta) = A_0 A_1 W_r(f_\tau) w_a(\eta - \eta_c)
 \exp\left\{-j \frac{4\pi (f_0 + f_\tau) R(\eta)}{c}\right\}
 \exp\left\{-j \frac{\pi f_\tau^2}{K_r}\right\} \tag{6}
$$

第二个指数项就是距离压缩要抵消的二次相位，而第一项里的 $f_0 + f_\tau$ 是后面所有耦合的来源。小斜视角把这一项近似成 $f_0$，大斜视角必须原样保留。

## 3 方位向 FFT：二维频谱
对 $\eta$ 做 FFT，需要计算积分 $\int S_0(f_\tau,\eta)\exp\lbrace -j 2\pi f_\eta \eta\rbrace  d\eta$。总相位为

$$
 \Theta(\eta) = -\frac{4\pi (f_0 + f_\tau) \sqrt{R_0^2 + V_r^2 \eta^2}}{c} - 2\pi f_\eta \eta \tag{7}
$$

对 $\eta$ 求导（复合函数求导）：

$$
 \frac{d\Theta(\eta)}{d\eta} = -\frac{4\pi (f_0 + f_\tau)}{c} \cdot \frac{V_r^2 \eta}{\sqrt{R_0^2 + V_r^2 \eta^2}} - 2\pi f_\eta = 0 \tag{8}
$$

先得到时频关系：

$$
 f_\eta = -\frac{2 V_r^2 (f_0 + f_\tau) \eta}{c \sqrt{R_0^2 + V_r^2 \eta^2}} \tag{9}
$$

记 $\rho = \sqrt{R_0^2 + V_r^2 \eta^2}$，把式(9)两边平方：

$$
 \frac{c^2 f_\eta^2}{4 V_r^2 (f_0 + f_\tau)^2} = \frac{V_r^2 \eta^2}{\rho^2}
 \quad\Longrightarrow\quad
 1 - \frac{c^2 f_\eta^2}{4 V_r^2 (f_0 + f_\tau)^2} = \frac{R_0^2}{\rho^2} \tag{10}
$$

引入二维频域徙动因子

$$
 D_{2df}(f_\tau, f_\eta, V_r) = \sqrt{1 - \frac{c^2 f_\eta^2}{4 V_r^2 (f_0 + f_\tau)^2}} \tag{11}
$$

式(10) 给出 $\rho = R_0 / D_{2df}(f_\tau, f_\eta, V_r)$，这就是把驻点代回相位时要用的关键关系。由式(9) 还能直接反解出驻点

$$
 \eta^* = -\frac{c R_0 f_\eta}{2 (f_0 + f_\tau) V_r^2 D_{2df}(f_\tau, f_\eta, V_r)} \tag{12}
$$

把式(12) 代回式(7)，两项分别化简：

$$
 -\frac{4\pi (f_0 + f_\tau) \rho}{c} = -\frac{4\pi R_0 (f_0 + f_\tau)}{c D_{2df}(f_\tau, f_\eta, V_r)},
 \qquad
 -2\pi f_\eta \eta^* = +\frac{\pi c R_0 f_\eta^2}{V_r^2 (f_0 + f_\tau) D_{2df}(f_\tau, f_\eta, V_r)} \tag{13}
$$

第二项用 $c^2 f_\eta^2 = 4 V_r^2 (f_0 + f_\tau)^2 (1 - D_{2df}^2(f_\tau, f_\eta, V_r))$ 换掉分子，得

$$
 \frac{\pi c R_0 f_\eta^2}{V_r^2 (f_0 + f_\tau) D_{2df}(f_\tau, f_\eta, V_r)}
 = \frac{4\pi R_0 (f_0 + f_\tau) (1 - D_{2df}^2(f_\tau, f_\eta, V_r))}{c D_{2df}(f_\tau, f_\eta, V_r)} \tag{14}
$$

两项相加，$1 - D_{2df}^2(f_\tau, f_\eta, V_r)$ 与前面的 $-1$ 相消：

$$
 \Theta(f_\tau, f_\eta) = -\frac{4\pi R_0 (f_0 + f_\tau) D_{2df}(f_\tau, f_\eta, V_r)}{c} - \frac{\pi f_\tau^2}{K_r}
 \equiv \theta_a(f_\tau, f_\eta) \tag{15}
$$

于是二维频谱为

$$
 S_{2df}(f_\tau, f_\eta) = A_0 A_1 A_2 W_r(f_\tau) W_a(f_\eta - f_{\eta_c}) \exp\{j \theta_a(f_\tau, f_\eta)\} \tag{16}
$$

$\theta_a(f_\tau, f_\eta)$ 里两项分别是距离徙动（带着 $D_{2df}(f_\tau, f_\eta, V_r)$）和距离调制，耦合就藏在 $D_{2df}(f_\tau, f_\eta, V_r)$ 同时依赖 $f_\tau$ 与 $f_\eta$ 这件事上。

## 4 距离向 IFFT：距离多普勒域
对 $f_\tau$ 做 IFFT，需要计算积分 $\int S_{2df}(f_\tau,f_\eta)\exp\lbrace j 2\pi f_\tau \tau\rbrace  df_\tau$。如果直接对式(15) 求驻点，会得到 $f_\tau$ 的四次方程，代数量太大。工程上的做法是在 $f_\tau = 0$ 处把相位对 $f_\tau$ 做泰勒展开，保留到二次项。

把式(15) 里的根号写成

$$
 (f_0 + f_\tau) D_{2df}(f_\tau, f_\eta, V_r) = \sqrt{(f_0 + f_\tau)^2 - \frac{c^2 f_\eta^2}{4 V_r^2}} \equiv g(f_\tau) \tag{17}
$$

记 $D(f_\eta, V_r) = D_{2df}(f_\tau, f_\eta, V_r)\big\rvert_{f_\tau = 0}$，在 $f_\tau = 0$ 处展开

$$
 g(0) = f_0 D(f_\eta, V_r), \qquad
 g'(0) = \frac{1}{D(f_\eta, V_r)}, \qquad
 g''(0) = -\frac{c^2 f_\eta^2}{4 V_r^2 f_0^3 D^3(f_\eta, V_r)} \tag{18}
$$

于是

$$
    g(f_\tau) \approx f_0 D(f_\eta, V_r) + \frac{f_\tau}{D(f_\eta, V_r)}
    - \frac{c^2 f_\eta^2}{8 V_r^2 f_0^3 D^3(f_\eta, V_r)} f_\tau^2 \tag{19}
$$

代回式(15)，记

$$
 Z(R_0, f_\eta) = \frac{c R_0 f_\eta^2}{2 V_r^2 f_0^3 D^3(f_\eta, V_r)} \tag{20}
$$

得到展开后的相位

$$
 \theta_a(f_\tau, f_\eta) \approx -\frac{4\pi R_0 f_0 D(f_\eta, V_r)}{c} - \frac{4\pi R_0 f_\tau}{c D(f_\eta, V_r)} + \pi Z(R_0, f_\eta) f_\tau^2 - \frac{\pi f_\tau^2}{K_r} \tag{21}
$$

IFFT 的被积相位是 $\theta_a(f_\tau, f_\eta) + 2\pi f_\tau \tau$，对 $f_\tau$ 求导并令其为零：

$$
 \frac{d\theta_a}{df_\tau} + 2\pi \tau = -\frac{4\pi R_0}{c D(f_\eta, V_r)} + 2\pi Z(R_0, f_\eta) f_\tau - \frac{2\pi f_\tau}{K_r} + 2\pi \tau = 0 \tag{22}
$$

解得驻点

$$
 f_\tau^* = \frac{K_r}{1 - K_r Z(R_0, f_\eta)} \left[ \tau - \frac{2 R_0}{c D(f_\eta, V_r)} \right] \tag{23}
$$

驻点条件还可以改写成

$$
 -\frac{4\pi R_0}{c D(f_\eta, V_r)} + 2\pi \tau = -2\pi f_\tau^* \left(Z(R_0, f_\eta) - \frac{1}{K_r}\right) \tag{24}
$$

把式(23) 与式(24) 代回，被积总相位（式(21) 加上 IFFT 的线性相位 $2\pi f_\tau \tau$）在驻点处为

$$
    \begin{aligned}
    \theta_a(f_\tau^*) + 2\pi f_\tau^*\tau
    &= -\frac{4\pi R_0 f_0 D(f_\eta, V_r)}{c}
    + f_\tau^*\left(-\frac{4\pi R_0}{c D(f_\eta, V_r)} + 2\pi\tau\right)
    + \pi f_\tau^{*2}\left(Z(R_0, f_\eta) - \frac{1}{K_r}\right)\\
    &= -\frac{4\pi R_0 f_0 D(f_\eta, V_r)}{c} - \pi f_\tau^{*2}\left(Z(R_0, f_\eta) - \frac{1}{K_r}\right) \\
    &= -\frac{4\pi R_0 f_0 D(f_\eta, V_r)}{c} + \pi f_\tau^{*2}\left(\frac{1}{K_r} - Z(R_0, f_\eta)\right)\\
    &= -\frac{4\pi R_0 f_0 D(f_\eta, V_r)}{c} + \pi K_m \left[ \tau - \frac{2 R_0}{c D(f_\eta, V_r)} \right]^2
    \end{aligned} \tag{25}
$$

最后一步用到 $f_\tau^{\ast 2}\left(\dfrac{1}{K_r} - Z(R_0, f_\eta)\right) = \dfrac{K_r}{1 - K_r Z(R_0, f_\eta)}\left[\tau - \dfrac{2R_0}{cD(f_\eta, V_r)}\right]^2$，其中

$$
 K_m = \frac{K_r}{1 - K_r Z(R_0, f_\eta)} \tag{26}
$$

包络在驻点处的拉伸因子 $1/(1 - K_r Z(R_0, f_\eta))$ 一并体现出来，最终距离多普勒域信号为

$$
 S_{rd}(\tau, f_\eta) = A w_r\left\{ \frac{1}{1 - K_r Z(R_0, f_\eta)} \left[ \tau - \frac{2 R_0}{c D(f_\eta, V_r)} \right] \right\} W_a(f_\eta - f_{\eta_c})
 \exp\left\{-j \frac{4\pi R_0 D(f_\eta, V_r) f_0}{c}\right\}
 \exp\left\{j \pi K_m \left[ \tau - \frac{2 R_0}{c D(f_\eta, V_r)} \right]^2\right\} \tag{27}
$$

三项含义：包络里的 $\tau - 2R_0/(cD(f_\eta, V_r))$ 说明距离徙动量由 $D(f_\eta, V_r)$ 决定；第一个指数项是方位调制相位，与 $f_\tau$ 无关了；第二个指数项是距离向调制，但调频率已经变成 $K_m$，它随 $f_\eta$ 变化——这就是交叉耦合在距离多普勒域留下的痕迹。

## 5 二次距离压缩与匹配滤波器
**SRC 调频率。** 式(20) 的 $Z(R_0, f_\eta)$ 取倒数就是调频率的量纲，定义

$$
 K_{src} = \frac{2 V_r^2 f_0^3 D^3(f_\eta, V_r)}{c R_0 f_\eta^2} = \frac{1}{Z(R_0, f_\eta)} \tag{28}
$$

式(26) 于是可以写成

$$
 K_m = \frac{K_r}{1 - K_r / K_{src}} \tag{29}
$$

$K_m < K_r$，说明交叉耦合等效地"拉低"了距离调频率。补偿它就是在距离频域乘

$$
 H_{src}(f_\tau) = \exp\left\{-j \pi \frac{f_\tau^2}{K_{src}}\right\} \tag{30}
$$

它和距离匹配滤波器 $H_r(f_\tau) = \exp\lbrace j \pi f_\tau^2 / K_r\rbrace $ 可以合并成一个

$$
 H_m(f_\tau) = \exp\left\{j \pi f_\tau^2 \left( \frac{1}{K_r} - \frac{1}{K_{src}} \right)\right\}
 = \exp\left\{j \pi \frac{f_\tau^2}{K_m}\right\} \tag{31}
$$

**距离徙动校正。** 式(27) 的包络给出精确的距离徙动

$$
 \Delta R(f_\eta) = R_{rd}(f_\eta) - R_0 = R_0 \left[ \frac{1 - D(f_\eta, V_r)}{D(f_\eta, V_r)} \right] \tag{32}
$$

小斜视角下把 $D(f_\eta, V_r)$ 展开、只留到 $f_\eta^2$ 项，它就退化成 $\lambda^2 R_0 f_\eta^2/(8 V_r^2)$。

## 6 SRC 的三种实现方式
$K_{src}$ 同时依赖 $R_0$ 和 $f_\eta$，实现时要在精度和算力之间取舍，工程上有三条路。

**做法一：在距离多普勒域跟 RCMC 插值一起做。** 处理域是 $S_{rd}(\tau, f_\eta)$。这里距离维是时间 $\tau$，没法直接乘 $f_\tau$ 的二次相位，所以不用频域相乘，改用重采样：对每个 $f_\eta$ 和 $\tau$ 算出距离偏移 $\Delta\tau = 2\Delta R(f_\eta)/c$，原采样点 $\tau_n$，新采样点 $\tau_m^{\prime}= \tau_m + \Delta\tau$，插值核里同时带上 SRC：

$$
 S_{rd\_corrected}(\tau_m', f_\eta) = \sum_{n} S_{rd}(\tau_n, f_\eta) \cdot h_{src}(\tau_m' - \tau_n, f_\eta) \cdot \operatorname{sinc}\left[ B_r (\tau_m' - \tau_n) \right] \tag{33}
$$

其中 $h_{src}(\tau, f_\eta) = \operatorname{IFFT}\lbrace H_{src}(f_\tau)\rbrace $。这一步同时完成 RCMC 和二次距离压缩，精度最高，能完整适配 $K_{src}$ 的空变性；代价是插值核计算量大、访存不规则。

**做法二：在二维频域乘相位。** 处理域是 $S_{2df}(f_\tau, f_\eta)$。问题是 $K_{src}$ 随 $R_0$ 变化，全图没法用一套相位。做法是把数据沿距离向切成若干子块，块内认为 $R_0 \approx R_{ref}$，块间留重叠消除边界效应，块内做

$$
 S_{2df\_corrected}(f_\tau, f_\eta) = S_{2df}(f_\tau, f_\eta) \cdot \exp\left\{-j \pi \frac{f_\tau^2}{K_{src}}\right\} \tag{34}
$$

能用 FFT 高效实现，精度也够，是工程上的主流做法，代价是分块和重叠带来的复杂度。

**做法三：在距离频率-方位时域做，忽略方位频率依赖。** 处理域是 $S_0(f_\tau, \eta)$，此时还没有 $f_\eta$ 信息，$D(f_\eta, V_r)$ 算不出来，只能用参考方位频率（比如多普勒中心 $f_{\eta c}$）算一个常数 $K_{src}$。把它并进距离匹配滤波器：

$$
 H_{total}(f_\tau) = H_r(f_\tau) \cdot \exp\left\{-j \pi \frac{f_\tau^2}{K_{src}}\right\}
 = \exp\left\{j \pi f_\tau^2 \left( \frac{1}{K_r} - \frac{1}{K_{src}} \right)\right\} \tag{35}
$$

等效调频率为 $K_m = \dfrac{K_r K_{src}}{K_{src} - K_r}$。计算量最小，距离压缩和 SRC 一步做完；代价是偏离参考频率的地方有残余误差，斜视角大或分辨率要求高时图像边缘会散焦。

## 7 方位压缩与最终图像
RCMC 与 SRC 之后（假设已校正干净），距离包络对齐到 $2R_0/c$，信号变成

$$
 S_{rd2}(\tau, f_\eta) = A p_r\left[\tau - \frac{2R_0}{c}\right] W_a(f_\eta - f_{\eta_c}) \exp\left\{-j \frac{4\pi R_0 D(f_\eta, V_r) f_0}{c}\right\} \tag{36}
$$

**方位匹配滤波。** 取式(36) 里方位相位的共轭：

$$
 H_{az}(f_\eta) = \exp\left\{j \frac{4\pi R_0 D(f_\eta, V_r) f_0}{c}\right\} \tag{37}
$$

相乘后相位被补偿干净：

$$
 S_3(\tau, f_\eta) = S_{rd2}(\tau, f_\eta) H_{az}(f_\eta) = A p_r\left[\tau - \frac{2R_0}{c}\right] W_a(f_\eta - f_{\eta_c}) \tag{38}
$$

**方位 IFFT 与最终图像。** 对 $f_\eta$ 做 IFFT，被积相位对 $f_\eta$ 是线性的，没有驻点，直接积分。$W_a(f_\eta - f_{\eta_c})$ 对应时域 $w_a(\eta)\exp\lbrace j 2\pi f_{\eta_c} \eta\rbrace $，于是

$$
 s_{ac}(\tau, \eta) = A p_r\left[\tau - \frac{2R_0}{c}\right] p_a(\eta) \exp\{j 2\pi f_{\eta_c} \eta\} \tag{39}
$$

其中 $p_a(\eta)$ 是方位冲激响应，各常数相位并进 $A$。
*   包络 $p_r$ 把目标聚焦在 $\tau = 2R_0/c$，且与 $f_\eta$ 无关，说明 RCMC 和 SRC 已经把距离徙动与交叉耦合都补偿掉了。
*   包络 $p_a$ 把目标聚焦在 $\eta = 0$，也就是零多普勒位置。残余的线性相位 $\exp\lbrace j 2\pi f_{\eta_c} \eta\rbrace $ 来自多普勒中心，斜视时不为零，做干涉、极化这类要保留相位关系的处理时要先补偿掉。
