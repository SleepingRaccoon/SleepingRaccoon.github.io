---
title: Dechirp 宽带雷达成像：HRRP 与距离-速度耦合
order: 11
description: 从基带回波严格推到 RD 图：参考信号怎么选、共轭相乘的方向、快慢时间 FFT 的近似条件，以及距离-速度耦合项的来源与补偿。
---

## 1 符号约定与基本假设
*   $\hat{t}$：**快时间**（距离向）；$t_m$：**慢时间**（方位向）。
*   $R_i(t_m) = R_{i,0} + v_i t_m$：第 $i$ 个散射中心的瞬时斜距，规定 $v_i > 0$ 表示目标**远离**雷达。
*   $c$：光速；$\tau_i(t_m) = \frac{2R_i(t_m)}{c}$：回波时延。
*   $R_{\mathrm{ref}}$：参考距离；$\tau_{\mathrm{ref}} = \frac{2R_{\mathrm{ref}}}{c}$：参考时延。
*   $R_{\Delta i}(t_m) = R_i(t_m) - R_{\mathrm{ref}}$：相对距离，目标比参考近时 $R_{\Delta i} < 0$。
*   $\gamma$：LFM 调频斜率；$T_p$：脉宽；$B = \lvert \gamma\rvert T_p$：带宽。
*   $f_c$：载频；$\lambda = c/f_c$：波长；$T_{\mathrm{CPI}}$：相干处理间隔。
*   $A_i$：第 $i$ 个散射中心的复幅度；$N$：散射中心个数。

## 2 精确的基带信号模型
### 2.1 发射基带信号

$$
s_t(\hat{t}) = \operatorname{rect}\left(\frac{\hat{t}}{T_p}\right) \exp\left(j\pi \gamma \hat{t}^2\right) \tag{1}
$$

### 2.2 目标基带回波
第 $i$ 个散射中心的基带回波为

$$
s_{r,i}(\hat{t}, t_m) = A_i \operatorname{rect}\left(\frac{\hat{t} - \tau_i(t_m)}{T_p}\right) \exp\left[j\pi \gamma \left(\hat{t} - \tau_i(t_m)\right)^2\right] \exp\left[-j2\pi f_c \tau_i(t_m)\right] \tag{2}
$$

其中 $\exp\left[-j2\pi f_c \tau_i(t_m)\right]$ 是慢时间多普勒的唯一来源，必须保留。

### 2.3 参考信号
参考信号脉宽 $T_{\mathrm{ref}}$ 必须覆盖整个接收窗口，通常取 $T_{\mathrm{ref}} \ge T_p + \Delta\tau_{\max}$（$\Delta\tau_{\max}$ 为最大回波时延差），这样两个矩形窗相乘后的有效积分时间 $T_{\mathrm{eff}} \approx T_p$。参考距离 $R_{\mathrm{ref}}$ 必须选在目标场景中心：偏离太远时差频频率 $f_{\mathrm{if}} = \frac{2\gamma}{c}\lvert R_{\Delta i}\rvert$ 会超出 ADC 的低通带宽，回波被直接滤掉。

$$
s_{\mathrm{ref}}(\hat{t}) = \operatorname{rect}\left(\frac{\hat{t} - \tau_{\mathrm{ref}}}{T_{\mathrm{ref}}}\right) \exp\left[j\pi \gamma \left(\hat{t} - \tau_{\mathrm{ref}}\right)^2\right] \tag{3}
$$

## 3 Dechirp 混频与精确相位展开
### 3.1 共轭相乘的方向
为什么不写成 $s_{\mathrm{ref}} \cdot s_r^{\ast}$（那样相位里直接就是 $R_i - R_{\mathrm{ref}}$，看着更顺）？标准工程做法是**回波乘参考的共轭**，即 $s_r \cdot s_{\mathrm{ref}}^{\ast}$，推导一遍就知道差在哪：

$$
s_{\mathrm{IF}} = s_r \cdot s_{\mathrm{ref}}^{\ast} = A_i \operatorname{rect}(\cdot) \exp\left[j\pi \gamma \left((\hat{t} - \tau_i)^2 - (\hat{t} - \tau_{\mathrm{ref}})^2\right)\right] \exp\left[-j2\pi f_c \tau_i\right] \tag{4}
$$

展开相位项：

$$
\Delta\Phi = \pi \gamma \left[-2\hat{t}\tau_i + \tau_i^2 + 2\hat{t}\tau_{\mathrm{ref}} - \tau_{\mathrm{ref}}^2\right] - 2\pi f_c \tau_i = 2\pi \gamma (\tau_{\mathrm{ref}} - \tau_i)\hat{t} + \pi \gamma (\tau_i^2 - \tau_{\mathrm{ref}}^2) - 2\pi f_c \tau_i \tag{5}
$$

代入 $\tau_{\mathrm{ref}} - \tau_i = -\frac{2(R_i - R_{\mathrm{ref}})}{c} = -\frac{2R_{\Delta i}}{c}$：

$$
\Delta\Phi = -2\pi \gamma \frac{2R_{\Delta i}}{c}\hat{t} + \pi \gamma (\tau_i^2 - \tau_{\mathrm{ref}}^2) - 2\pi f_c \tau_i \tag{6}
$$

于是差频频率 $f_{\mathrm{if}} = -\frac{2\gamma}{c} R_{\Delta i}$。目标比参考近（$R_{\Delta i} < 0$）时 $f_{\mathrm{if}} > 0$，落在正频率轴上，便于 FFT 处理；若反过来写成 $s_{\mathrm{ref}} \cdot s_r^{\ast}$，差频频率变号，频率轴翻转，读数与距离的对应关系也就反了。这就是标准做法要取回波乘参考共轭的原因。

### 3.2 常数相位项的展开与忽略条件
令 $\Delta\tau = \tau_i - \tau_{\mathrm{ref}} = \frac{2R_{\Delta i}}{c}$，则 $\tau_i = \tau_{\mathrm{ref}} + \Delta\tau$，式(6) 里的常数相位为

$$
\Phi_{\mathrm{const}} = \pi \gamma (\tau_i^2 - \tau_{\mathrm{ref}}^2) - 2\pi f_c \tau_i = \pi \gamma (2\tau_{\mathrm{ref}}\Delta\tau + \Delta\tau^2) - 2\pi f_c (\tau_{\mathrm{ref}} + \Delta\tau) \tag{7}
$$

按来源拆成四项：

*   $\pi \gamma \Delta\tau^2$：**残余视频相位（RVP）**。当 $B\Delta\tau \ll 1$（相对距离差远小于距离分辨率）时 $\pi \gamma \Delta\tau^2 = \pi \Delta f \Delta\tau \ll \pi$，可忽略。
*   $2\pi \gamma \tau_{\mathrm{ref}} \Delta\tau$：**距离-速度耦合项**（Dechirp 特有）。参考距离不大、目标速度不高时数值较小；高精度成像中不能忽略，必须补偿，见 7 节。
*   $-2\pi f_c \tau_{\mathrm{ref}}$：与目标无关的常数相位，不影响成像，直接忽略。
*   $-2\pi f_c \Delta\tau = -\frac{4\pi}{\lambda}R_{\Delta i}$：**多普勒相位历史**，绝对不能忽略，是慢时间 FFT 的核心。

## 4 快时间维 FFT（距离维压缩）
对 $s_{\mathrm{IF}}(\hat{t}, t_m)$ 沿快时间 $\hat{t}$ 做 FFT：

$$
S(f, t_m) = \int s_{\mathrm{IF}}(\hat{t}, t_m) \exp\left(-j2\pi f \hat{t}\right) \mathrm{d}\hat{t} \tag{8}
$$

利用矩形窗的傅里叶变换：

$$
S(f, t_m) = \sum_{i=1}^{N} A_i T_p \operatorname{sinc}\left[ T_p \left( f + \frac{2\gamma R_{\Delta i}(t_m)}{c} \right) \right] \exp\left[j\Phi_{\mathrm{const}}(t_m)\right] \tag{9}
$$

这里 $f$ 是差频频率，峰值位于 $f = -\frac{2\gamma}{c} R_{\Delta i}(t_m)$。由于 $R_{\Delta i}(t_m) = R_{\Delta i,0} + v_i t_m$，峰值频率会随慢时间变化，这就是**距离走动（MTRC）**。

## 5 慢时间维 FFT（多普勒维压缩与 RD 图）
### 5.1 展开多普勒相位
将 $\tau_i(t_m) = \frac{2(R_{i,0} + v_i t_m)}{c}$ 代入式(7) 的核心项 $-2\pi f_c \Delta\tau$：

$$
\Phi_{\mathrm{dop}}(t_m) = -2\pi f_c \frac{2(R_{\Delta i,0} + v_i t_m)}{c} = -\frac{4\pi}{\lambda} R_{\Delta i,0} - \frac{4\pi v_i}{\lambda} t_m \tag{10}
$$

即多普勒频率

$$
f_{d,i} = -\frac{2v_i}{\lambda} \tag{11}
$$

$v_i > 0$（远离）时 $f_{d,i} < 0$，与第 1 节的符号约定一致。

### 5.2 忽略耦合项的条件
忽略距离-速度耦合项 $2\pi \gamma \tau_{\mathrm{ref}} \Delta\tau$ 与 RVP 后，常数相位简化为

$$
\Phi_{\mathrm{const}}(t_m) \approx -\frac{4\pi}{\lambda} R_{\Delta i,0} - \frac{4\pi v_i}{\lambda} t_m \tag{12}
$$

### 5.3 慢时间 FFT 与 RD 图
对慢时间 $t_m$ 做 FFT（观测长度为 $T_{\mathrm{CPI}}$），得到 RD 图

$$
S(f, f_d) = \sum_{i=1}^{N} A_i T_p T_{\mathrm{CPI}} \operatorname{sinc}\left[ T_p \left( f + \frac{2\gamma R_{\Delta i,0}}{c} \right) \right] \operatorname{sinc}\left[ T_{\mathrm{CPI}} \left( f_d + \frac{2v_i}{\lambda} \right) \right] \exp(j\Theta_i) \tag{13}
$$

### 5.4 距离走动（MTRC）的忽略条件
式(13) 假设慢时间 FFT 期间距离维 sinc 峰不移动，这要求

$$
v_i T_{\mathrm{CPI}} \ll \rho_r = \frac{c}{2B} \tag{14}
$$

即目标在 CPI 内的移动距离远小于距离分辨率。若 $v_i T_{\mathrm{CPI}} \ge \rho_r$，则 $f = -\frac{2\gamma}{c}(R_{\Delta i,0} + v_i t_m)$ 会让距离峰随 $t_m$ 倾斜，此时不能直接做慢时间 FFT，必须先用《[Keystone 变换](/radar/05_Keystone变换/)》或 Radon 变换校正 MTRC，否则 RD 图上的目标会散焦成一条斜线。

## 6 最终 RD 图的物理图景
由式(13)，宽带目标的 RD 图 $\lvert S(f, f_d)\rvert$ 有以下特征：

*   **距离维（横轴 $f$）**：由 sinc 决定，峰值位于 $f = -\frac{2\gamma}{c}R_{\Delta i,0}$。目标尺寸大于 $\rho_r$ 时沿距离轴展开多个散射中心，形成**高分辨一维距离像（HRRP）**。
*   **多普勒维（纵轴 $f_d$）**：峰值位于 $f_d = -\frac{2v_i}{\lambda}$。刚体目标各散射中心 $v_i$ 相同，亮点处于同一高度；目标有转动时各散射中心 $v_i$ 不同，多普勒维展开成**二维几何轮廓**。
*   **相位 $\Theta_i$**：包含残余 RVP、耦合项与初相。同一距离-多普勒单元内有多个散射中心时，复数相加会产生干涉（Glint 效应），幅度起伏。
*   **MTRC**：$v_i T_{\mathrm{CPI}} \ge \rho_r$ 时亮线倾斜、散焦，必须做运动补偿。

从基带回波出发，经 Dechirp 混频（回波乘参考共轭）、快时间 FFT（距离压缩）与慢时间 FFT（多普勒压缩），宽带目标的 RD 图就是一幅**二维复数散射中心分布图**：距离维给出目标沿径向的几何结构，多普勒维给出运动与微动特征。推导中被忽略的 RVP、距离-速度耦合与 MTRC 都有明确的数学不等式条件，工程上按指标决定是否补偿。

## 7 距离-速度耦合项详解
第 3.2 节把 $2\pi \gamma \tau_{\mathrm{ref}} \Delta\tau$ 归入"能忽略则忽略、该补偿就补偿"一类，这一节单独把它拆开，说明它凭什么把距离与速度绑在一起。

### 7.1 展开相对时延，暴露速度变量
相对时延为

$$
\Delta\tau = \tau_i - \tau_{\mathrm{ref}} = \frac{2R_\Delta(t_m)}{c},\qquad R_\Delta(t_m) = R_{\Delta,0} + v t_m \tag{15}
$$

其中 $R_{\Delta,0}$ 是初始相对距离。代入得

$$
\Delta\tau = \frac{2R_{\Delta,0}}{c} + \frac{2v t_m}{c} \tag{16}
$$

### 7.2 代入耦合项
把式(16) 代入 $2\pi \gamma \tau_{\mathrm{ref}} \Delta\tau$：

$$
\Phi_{\mathrm{coup}} = 2\pi \gamma \tau_{\mathrm{ref}} \left(\frac{2R_{\Delta,0}}{c} + \frac{2v t_m}{c}\right) = \underbrace{\frac{4\pi \gamma \tau_{\mathrm{ref}} R_{\Delta,0}}{c}}_{\text{常数相位}} + \underbrace{\frac{4\pi \gamma \tau_{\mathrm{ref}} v}{c} t_m}_{\text{随慢时间线性变化}} \tag{17}
$$

### 7.3 为什么叫"距离-速度耦合"
式(17) 的第二项对 $t_m$ 是线性的：线性相位就是频率，对慢时间做 FFT 时它会产生一个附加多普勒频率

$$
\Delta f_d = \frac{2\gamma \tau_{\mathrm{ref}} v}{c} = \frac{4\gamma R_{\mathrm{ref}} v}{c^2} \tag{18}
$$

其中用到 $\tau_{\mathrm{ref}} = \frac{2R_{\mathrm{ref}}}{c}$。这个附加频率**正比于参考距离 $R_{\mathrm{ref}}$，也正比于目标速度 $v$**：

*   多普勒维测出的"速度"不仅取决于真实 $v$，还取决于所选的参考距离 $R_{\mathrm{ref}}$；
*   快时间维的差频频率 $f_{\mathrm{if}} = -\frac{2\gamma}{c} R_\Delta(t_m)$ 中含 $v t_m$，所以距离维峰值位置会随慢时间移动，即距离走动。

距离与速度通过这个乘积项缠在一起、无法各自独立读出，这就是**距离-速度耦合（RDC）**的来源。

### 7.4 耦合带来的后果
*   **散焦**：亮斑在距离维随 $t_m$ 倾斜，不补偿就做慢时间 FFT，能量无法聚焦，多普勒维主瓣展宽、幅度下降。
*   **测速偏差**：多普勒频率变成 $f_d = -\frac{2v}{\lambda} + \Delta f_d$，多了一项。
*   **依赖参考距离**：改变 $R_{\mathrm{ref}}$，测出的多普勒频率跟着变，显然不是真实物理速度。

### 7.5 忽略条件（工程边界）
要在推导中省掉这一项，需要 CPI 内它的相位变化远小于 $\pi$：

$$
\frac{4\pi \gamma \tau_{\mathrm{ref}} v}{c} t_m \ll \pi
\quad\Longrightarrow\quad
\frac{4\gamma R_{\mathrm{ref}} v T_{\mathrm{CPI}}}{c^2} \ll 1 \tag{19}
$$

带宽大（$\gamma$ 大）、参考距离远、目标速度快、观测时间长时，这一项**不能**忽略。

### 7.6 工程上如何解耦
先粗测速得到 $\hat{v}$，再构造补偿相位

$$
\Phi_{\mathrm{comp}} = -2\pi \gamma \tau_{\mathrm{ref}} \frac{2\hat{v} t_m}{c} \tag{20}
$$

在慢时间域乘上这个补偿因子，把 $2\pi \gamma \tau_{\mathrm{ref}} \Delta\tau$ 中的速度耦合项抵消，然后再做慢时间 FFT，才能得到聚焦良好的 RD 图。

### 7.7 小结
$2\pi \gamma \tau_{\mathrm{ref}} \Delta\tau$ 之所以叫耦合项，原因是 $\Delta\tau$ 里藏着 $v t_m$，它产生附加多普勒频率 $\frac{4\gamma R_{\mathrm{ref}} v}{c^2}$，同时造成距离维走动与多普勒维偏移，使测距与测速互相干扰，必须通过运动补偿（去斜、Keystone 变换等）解耦。

## 8 速查

$$
s_{r,i}(\hat{t}, t_m) = A_i \operatorname{rect}\left(\frac{\hat{t}-\tau_i(t_m)}{T_p}\right) e^{j\pi \gamma \left(\hat{t}-\tau_i(t_m)\right)^2} e^{-j2\pi f_c \tau_i(t_m)},\qquad s_{\mathrm{IF}} = s_r \cdot s_{\mathrm{ref}}^{\ast}
$$

$$
f_{\mathrm{if}} = -\frac{2\gamma}{c} R_{\Delta i},\qquad \Phi_{\mathrm{const}} = \pi\gamma \Delta\tau^2 + 2\pi\gamma \tau_{\mathrm{ref}} \Delta\tau - 2\pi f_c \tau_{\mathrm{ref}} - \frac{4\pi}{\lambda} R_{\Delta i}
$$

$$
S(f, f_d) = \sum_{i=1}^{N} A_i T_p T_{\mathrm{CPI}} \operatorname{sinc}\left[ T_p \left( f + \frac{2\gamma R_{\Delta i,0}}{c} \right) \right] \operatorname{sinc}\left[ T_{\mathrm{CPI}} \left( f_d + \frac{2v_i}{\lambda} \right) \right] e^{j\Theta_i}
$$

$$
v_i T_{\mathrm{CPI}} \ll \rho_r = \frac{c}{2B},\qquad \Delta f_d = \frac{4\gamma R_{\mathrm{ref}} v}{c^2},\qquad \Phi_{\mathrm{comp}} = -2\pi \gamma \tau_{\mathrm{ref}} \frac{2\hat{v} t_m}{c}
$$

一句话：回波乘参考共轭得到差频 $f_{\mathrm{if}} = -\frac{2\gamma}{c}R_{\Delta i}$，快时间 FFT 把它压成距离维 sinc，慢时间 FFT 把载频相位 $-\frac{4\pi}{\lambda}R_{\Delta i}$ 压成多普勒维 sinc；RVP、距离-速度耦合与 MTRC 三项各有明确的不等式忽略条件，超了就必须补偿。
