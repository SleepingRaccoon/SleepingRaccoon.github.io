---
title: 小斜视角下的距离多普勒算法
order: 12
description: 从小斜视基带回波出发，讲清距离压缩、方位 FFT、RCMC 与方位压缩四步，并说明每一步里哪些常数相位可以省、为什么能省。
---

## 0 符号约定
先把符号列清楚，后面直接引用。
*   $\tau$：**距离向快时间**（发射脉冲的传播时间）。
*   $\tau^{*}, \eta^{*}$：距离向、方位向驻定相位求出的**驻定点**，是为写频域形式引入的变量，不是快时间 $\tau$ 和慢时间 $\eta$，不要混用。
*   $\eta$：**方位向慢时间**（雷达飞行的时间）。
*   $\eta_c$：**波束中心穿越时刻**，雷达波束中心正好扫过目标的慢时间。
*   $\eta = 0$：**零多普勒时刻**，雷达到目标最近的时刻（斜距为 $R_0$）。波束前视（波束中心在零多普勒之前扫过目标）时 $\eta_c < 0$，后视时 $\eta_c > 0$。
*   $R(\eta)$：雷达与目标之间的**瞬时斜距**。
*   $R_0$：**最近斜距**（零多普勒时刻的斜距）。
*   $V_r$：雷达相对地面的有效速度。
*   $f_0$：雷达载频（$\lambda = c/f_0$）。
*   $K_r$：距离向调频率，即 LFM 的斜率。
*   $T_r$：发射脉冲宽度，$B_r = \lvert K_r \rvert T_r$ 为发射带宽。
*   $w_r(\cdot), w_a(\cdot)$：距离向、方位向包络（天线方向图加权）。
*   $p_r(\cdot), p_a(\cdot)$：压缩后的距离向、方位向脉冲响应。
*   $\gamma_{w,r}$：**IRW（冲激响应宽度）展宽因子**。频域乘锐化窗（比如 Kaiser 窗）压旁瓣（PSLR）的代价就是主瓣变宽：矩形窗 $\gamma_{w,r} = 1$，加窗后 $\gamma_{w,r} > 1$，具体值由窗型决定。
*   $f_\tau$：距离频率，与 $\tau$ 构成变换对。
*   $f_\eta$：方位频率（多普勒频率），与 $\eta$ 构成变换对。
*   $f_{\eta c}$：多普勒中心频率，斜视时不为零。
*   $K_a = \dfrac{2V_r^2}{\lambda R_0}$：方位向调频率。

## 1 距离压缩
雷达接收解调后的基带信号模型为

$$
 s_0(\tau, \eta) = A_0 w_r\left[\tau - \frac{2R(\eta)}{c}\right] w_a(\eta - \eta_c) \exp\left\lbrace-j \frac{4\pi f_0 R(\eta)}{c}\right\rbrace \exp\left\lbracej \pi K_r \left(\tau - \frac{2R(\eta)}{c}\right)^2\right\rbrace \tag{1}
$$

其中 $A_0$ 是**复数幅度**：发射功率、天线增益、目标 RCS、接收链路增益与固定相移都归到它里面。在一个 CPI 内这些量都视为常数，所以下面推导只关心相位，幅度一概并进 $A_0$ 不展开。

式(1)里有两类因子，一类管"信号长什么样"，一类管"相位随慢时间怎么变"：

*   $w_r\left[\tau - \dfrac{2R(\eta)}{c}\right]$ 和 $\exp\left\lbracej \pi K_r \left(\tau - \dfrac{2R(\eta)}{c}\right)^2\right\rbrace$：**被时延整体搬移的一段脉冲**。距离窗只是这段 LFM 的"存在范围"，LFM 的中心和窗的中心都在 $\tau = 2R(\eta)/c$ 上，两者由同一个时延一起搬移。所以要把它们当一个整体：随 $\eta$ 缓慢移动的就是这一整段脉冲。距离压缩能把这个"块"压成尖峰，但**压不掉它在慢时间上的移动**——这正是后面距离徙动的来源，也是 RCMC 必须存在的理由。
*   $\exp\left\lbrace-j \dfrac{4\pi f_0 R(\eta)}{c}\right\rbrace$：**载频相位**。它随慢时间变化，是多普勒（方位向 LFM）的来源。

距离压缩在频域完成：对 $\tau$ 做 FFT，乘以频域匹配滤波器 $H(f_\tau) = \exp\lbracej \pi f_\tau^2 / K_r\rbrace$，再 IFFT 回时域。

**POSP 推导驻定点。** 对 $\tau$ 做 FFT，需要计算积分 $\int s_0(\tau,\eta) \exp\lbrace-j 2\pi f_\tau \tau\rbrace d\tau$。总相位为

$$
 \Theta(\tau) = \pi K_r \left[\tau - \frac{2R(\eta)}{c}\right]^2 - 2\pi f_\tau \tau \tag{2}
$$

求导并令导数为零，寻找驻定点：

$$
 \frac{d\Theta(\tau)}{d\tau} = 2\pi K_r \left[\tau - \frac{2R(\eta)}{c}\right] - 2\pi f_\tau = 0 \tag{3}
$$

解得驻定点：

$$
 \tau^{*} = \frac{2R(\eta)}{c} + \frac{f_\tau}{K_r} \tag{4}
$$

把驻点 $\tau^{*}$ 代回总相位 $\Theta(\tau)$，得到频域相位：

$$
 \Theta(f_\tau) = \pi K_r \left(\frac{f_\tau}{K_r}\right)^2 - 2\pi f_\tau \left(\frac{2R(\eta)}{c} + \frac{f_\tau}{K_r}\right) = -\pi \frac{f_\tau^2}{K_r} - \frac{4\pi f_\tau R(\eta)}{c} \tag{5}
$$

这个积分的驻定相位形式写全了是

$$
 \int s_0(\tau,\eta) e^{-j 2\pi f_\tau \tau} d\tau \;\approx\; A_0 W_r(f_\tau)\, \exp\lbrace\, j\Theta(\tau^{*}) \,\rbrace \sqrt{\frac{2\pi}{|\Theta''|}} \exp\left\lbrace j\frac{\pi}{4} \operatorname{sgn}(\Theta'') \right\rbrace
$$

其中三项分别是：
*   $W_r(f_\tau)$：距离窗 $w_r$ 经驻点 $\tau^{*}$ 尺缩后的频域形式。窗的自变量在驻点处取值 $\left.(\tau - 2R/c)\right\rvert_{\tau=\tau^{*}} = f_\tau/K_r$，所以 $w_r\left[\tau - 2R(\eta)/c\right]$ 变成 $w_r(f_\tau/K_r)$，记作 $W_r(f_\tau)$。
*   $\Theta(\tau^{*})$：驻点处的总相位，展开就是式(5)。
*   $\Theta''$：式(3)再求一次导，$\Theta'' = 2\pi K_r$ 是常数，所以这两个因子只跟 $K_r$ 有关，是固定增益与固定相移，与 $f_\tau$ 无关，并进 $A_0$ 即可。

（驻定相位原理见[《驻定相位原理》](../radar/驻定相位原理/)。）于是距离 FFT 后

$$
 S_0(f_\tau, \eta) = A_0 W_r(f_\tau) \exp\left\lbrace-j \pi \frac{f_\tau^2}{K_r}\right\rbrace \exp\left\lbrace-j \frac{4\pi f_\tau R(\eta)}{c}\right\rbrace \exp\left\lbrace-j \frac{4\pi f_0 R(\eta)}{c}\right\rbrace \tag{6}
$$

乘上匹配滤波器后二次相位被抵消：

$$
 S_0(f_\tau, \eta) H(f_\tau) = A_0 W_r(f_\tau) \exp\left\lbrace-j \frac{4\pi f_\tau R(\eta)}{c}\right\rbrace \exp\left\lbrace-j \frac{4\pi f_0 R(\eta)}{c}\right\rbrace \tag{7}
$$

**IFFT 回时域。** 对 $f_\tau$ 做 IFFT，需要计算积分 $\int S_0 H \exp\lbracej 2\pi f_\tau \tau\rbrace df_\tau$。二次相位已经被匹配滤波抵消，剩下的相位对 $f_\tau$ 是线性的，没有驻点，直接积分；只是 $W_r(f_\tau)$ 没有具体形式，这个积分写不出解析式，直接把它记成距离向冲激响应 $p_r$：

$$
 p_r\left[\tau - \frac{2R(\eta)}{c}\right]
 = \int W_r(f_\tau) \exp\left\lbracej 2\pi f_\tau \left[\tau - \frac{2R(\eta)}{c}\right]\right\rbrace df_\tau \tag{8}
$$

压缩后信号为

$$
 s_{rc}(\tau, \eta) = A_0 p_r\left[\tau - \frac{2R(\eta)}{c}\right] w_a(\eta - \eta_c) \exp\left\lbrace-j \frac{4\pi f_0 R(\eta)}{c}\right\rbrace \tag{9}
$$

$p_r$ 的形状由窗函数决定，矩形窗下是 $\operatorname{sinc}(B_r\tau)$，常数因子并进 $A_0$。压缩后的距离分辨率为 $\rho_r = \frac{c}{2} \frac{0.886 \gamma_{w,r}}{\lvert K_r \rvert T_r}$，其中 $T_r$ 为脉冲宽度，$K_r T_r$ 为带宽。

## 2 方位向 FFT
**抛物近似。** 小斜视角且孔径不大时，瞬时斜距作泰勒展开只保留到二次项：

$$
 R(\eta) = \sqrt{R_0^2 + V_r^2 \eta^2} \approx R_0 + \frac{V_r^2 \eta^2}{2R_0} \tag{10}
$$

成立条件是 $R_0 \gg V_r\eta$，且丢掉的四次项带来的相位误差远小于 $\pi/4$。

**方位向 LFM 信号。** 把式(10)代入式(9)的相位，忽略固定相位，只留随 $\eta$ 变化的项：

$$
 \Theta_{az}(\eta) = -\frac{4\pi f_0}{c} \left( \frac{V_r^2 \eta^2}{2R_0} \right) = -\pi \left( \frac{2V_r^2}{\lambda R_0} \right) \eta^2 \tag{11}
$$

记方位调频率 $K_a = \frac{2V_r^2}{\lambda R_0}$，方位向信号在时域就是一个线性调频信号 $\exp\lbrace-j \pi K_a \eta^2\rbrace$。

**POSP 推导驻定点。** 对 $\eta$ 做 FFT，需要计算积分 $\int s(\eta) \exp\lbrace-j 2\pi f_\eta \eta\rbrace d\eta$。总相位为

$$
 \Theta(\eta) = -\pi K_a \eta^2 - 2\pi f_\eta \eta \tag{12}
$$

求导并令导数为零：

$$
 \frac{d\Theta(\eta)}{d\eta} = -2\pi K_a \eta - 2\pi f_\eta = 0 \tag{13}
$$

解得驻定点：

$$
 \eta^{*} = -\frac{f_\eta}{K_a} \tag{14}
$$

二阶导 $\Theta'' = -2\pi K_a$ 同样只贡献常数。把驻点 $\eta^{*}$ 代回总相位，得到频域相位：

$$
 \Theta(f_\eta) = -\pi K_a \left(-\frac{f_\eta}{K_a}\right)^2 - 2\pi f_\eta \left(-\frac{f_\eta}{K_a}\right) = \pi \frac{f_\eta^2}{K_a} \tag{15}
$$

与距离向同理，这个积分的驻定相位形式写全了是

$$
 \int s(\eta) e^{-j 2\pi f_\eta \eta} d\eta \;\approx\; A_0 W_a(f_\eta - f_{\eta_c})\, \exp\lbrace\, j\Theta(\eta^{*}) \,\rbrace \sqrt{\frac{2\pi}{|\Theta''|}} \exp\left\lbrace j\frac{\pi}{4} \operatorname{sgn}(\Theta'') \right\rbrace
$$

其中三项分别是：
*   $W_a(f_\eta - f_{\eta_c})$：方位窗 $w_a$ 经驻点 $\eta^{*}$ 尺缩后的频域形式，与 $w_r \to W_r$ 同一回事。
*   $\Theta(\eta^{*})$：驻点处的总相位，展开就是式(15)。
*   $\Theta'' = -2\pi K_a$ 是常数，所以这两个因子只跟 $K_a$ 有关，一起并入 $A_0$ 即可。

**距离多普勒域信号。** 方位 FFT 之后，信号带上距离徙动与方位频域包络：

$$
 S_1(\tau, f_\eta) = A_0 p_r\left[\tau - \frac{2R_{rd}(f_\eta)}{c}\right] W_a(f_\eta - f_{\eta_c}) \exp\left\lbrace-j \frac{4\pi f_0 R_0}{c}\right\rbrace \exp\left\lbracej \pi \frac{f_\eta^2}{K_a}\right\rbrace \tag{16}
$$

瞬时斜距在频域表现为

$$
 R_{rd}(f_\eta) \approx R_0 + \frac{V_r^2}{2R_0} \left(\eta^{*}\right)^2 = R_0 + \frac{V_r^2}{2R_0} \left(-\frac{f_\eta}{K_a}\right)^2 = R_0 + \frac{\lambda^2 R_0 f_\eta^2}{8 V_r^2} \tag{17}
$$

其中随 $f_\eta$ 变化的那部分就是要校正的距离徙动量（RCM）：

$$
 \Delta R(f_\eta) = \frac{\lambda^2 R_0 f_\eta^2}{8 V_r^2} \tag{18}
$$

## 3 距离徙动校正（RCMC）
RCMC 的目标是把式(16)包络里的 $p_r[\tau - 2(R_0 + \Delta R(f_\eta))/c]$ 对齐成 $p_r(\tau - 2R_0/c)$，让同一目标在所有 $f_\eta$ 上落在同一个距离单元。

**插值不是卷积。** 插值是重采样，改变的是采样点的位置；卷积保持采样点不动，改变的是波形形状。对带限信号做偏移 $\Delta \tau$ 的重采样，可以写成原采样点的加权求和，权值是 sinc 核。之所以不直接用 FFT 做快速卷积实现这一步，是因为这里的插值核随距离和方位频率变化（空变），或者需要很长的核才能保证精度，代价太大。

**做法一：距离多普勒域 sinc 插值。** 对每个 $f_\eta$ 算出距离偏移 $\Delta \tau = 2\Delta R(f_\eta)/c$。原采样点 $\tau_n$，新采样点 $\tau_m' = \tau_m + \Delta \tau$，则

$$
 S_2(\tau_m', f_\eta) = \sum_{n} S_1(\tau_n, f_\eta) \cdot \text{sinc}\left[ B_r (\tau_m' - \tau_n) \right] \tag{19}
$$

实际实现取最近的 8 或 16 个点加权。每个 $f_\eta$、每个距离门 $R_0$ 对应的 $\Delta \tau$ 都不同，没法用统一的快速卷积，计算量很大。

**做法二：距离频域相位相乘。** 傅里叶变换的时移性质是 $x(\tau - \tau_0) \leftrightarrow X(f_\tau) \exp\lbrace-j 2\pi f_\tau \tau_0\rbrace$。要实现距离偏移 $2\Delta R(f_\eta)/c$，在距离频域乘

$$
 G_{rcmc}(f_\tau) = \exp\left\lbracej \frac{4\pi f_\tau \Delta R(f_\eta)}{c}\right\rbrace \tag{20}
$$

这个做法假设在一个有限的距离块内 $\Delta R(f_\eta)$ 不随 $R_0$ 变化，所以数据要沿距离向分块、块间重叠以消除边界效应。好处是能用 FFT 快速实现，代价是分块和重叠带来额外复杂度。

## 4 方位压缩
RCMC 之后（假设已校正干净），信号变成

$$
 S_2(\tau, f_\eta) = A_0 p_r\left(\tau - \frac{2R_0}{c}\right) W_a(f_\eta - f_{\eta_c}) \exp\left\lbrace-j \frac{4\pi f_0 R_0}{c}\right\rbrace \exp\left\lbracej \pi \frac{f_\eta^2}{K_a}\right\rbrace \tag{21}
$$

**方位匹配滤波。** 取式(21)中第二个指数项的复共轭作为滤波器：

$$
 H_{az}(f_\eta) = \exp\left\lbrace-j \pi \frac{f_\eta^2}{K_a}\right\rbrace \tag{22}
$$

相乘后频域相位被补偿干净：

$$
 S_3(\tau, f_\eta) = S_2(\tau, f_\eta) H_{az}(f_\eta) = A_0 p_r\left(\tau - \frac{2R_0}{c}\right) W_a(f_\eta - f_{\eta_c}) \exp\left\lbrace-j \frac{4\pi f_0 R_0}{c}\right\rbrace \tag{23}
$$

**方位 IFFT 与最终图像。** 对 $f_\eta$ 做 IFFT，此时相位对 $f_\eta$ 是线性的，没有驻点，直接积分。$W_a(f_\eta - f_{\eta_c})$ 对应时域 $w_a(\eta) \exp\lbracej 2\pi f_{\eta_c} \eta\rbrace$，于是得到二维压缩图像

$$
 s_{ac}(\tau, \eta) = A_0 p_r\left(\tau - \frac{2R_0}{c}\right) p_a(\eta) \exp\left\lbrace-j \frac{4\pi f_0 R_0}{c}\right\rbrace \exp\lbracej 2\pi f_{\eta_c} \eta\rbrace \tag{24}
$$

其中 $p_a(\eta)$ 是方位冲激响应。
*   包络 $p_r$ 把目标聚焦在 $\tau = 2R_0/c$，而且与 $f_\eta$ 无关，说明 RCM 已经校正掉。
*   包络 $p_a$ 把目标聚焦在 $\eta = 0$，也就是零多普勒位置。残余的线性相位 $\exp\lbracej 2\pi f_{\eta_c} \eta\rbrace$ 在 $\eta = 0$ 处为零；斜视时这一项不为零，做干涉、极化这类需要保留相位关系的处理时要先补偿掉。
