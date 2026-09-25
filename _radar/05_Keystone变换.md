---
title: Keystone 变换
order: 5
description: 从距离走动出发，推导 Keystone 尺度变换、离散实现（sinc 插值 / DFT-IFFT / CZT）与多普勒模糊补偿。
---

## 1 符号约定
先把符号列清楚，后面直接引用。
*   $\tau_i$：第 $i$ 个脉冲的回波时延，$\tau_i = \dfrac{2(R_0 + v\,iT_r)}{c}$。
*   $i$：慢时间脉冲序号，$i = 0,1,\dots,N-1$。
*   $T_r$：脉冲重复间隔（PRI），$f_r = 1/T_r$ 为脉冲重复频率（PRF），$T_{CPI} = NT_r$ 为一帧的观测时长。
*   $T_p$：脉宽，$B = KT_p$ 为带宽。$T_p$ 只出现在快时间，**不要与 $T_r$ 混用**。
*   $K, B$：调频斜率、带宽；距离分辨率 $\rho_r = c/(2B)$。
*   $f_c, \lambda$：载频、波长，$\lambda = c/f_c$。
*   $f$：距离频率（基带，带内 $\lvert f\rvert \le B/2$），与快时间构成变换对。
*   $R_0, v$：初始斜距、径向速度，本章假设匀速。
*   $D(f) = \dfrac{2v}{c}(f_c + f)$：距离频率 $f$ 处的**多普勒量**，该处的慢时间相位斜率为 $-2\pi D(f)T_r$。
*   $f_a$：慢时间序列上"看得见"的多普勒，$\lvert f_a\rvert \le f_r/2$；$k$ 为整数模糊数。
*   $\alpha(f) = \dfrac{f_c}{f_c + f}$：Keystone 尺度因子。

## 2 距离走动的来源
回波时延随脉冲线性增长：

$$
\tau_i = \frac{2(R_0 + v\,iT_r)}{c} \tag{1}
$$

脉压后沿快时间做 FFT，得到"距离频率–慢时间"域的数据

$$
X(f,i) = \text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\tau_i\right] \tag{2}
$$

把式(1)代入式(2)：

$$
X(f,i) = \text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\cdot\exp\left[-j2\pi(f+f_c)\frac{2v\,iT_r}{c}\right] \tag{3}
$$

式(3)第二个指数项按 $(f+f_c)$ 拆成两项，问题就全在这两项上：

*   $\exp\left[-j2\pi f\cdot\dfrac{2v\,iT_r}{c}\right]$：**走动项**，含 $f$。相位随脉冲累积，等效于距离位置随慢时间平移。
*   $\exp\left[-j2\pi f_c\cdot\dfrac{2v\,iT_r}{c}\right]$：**多普勒项**，不含 $f$，只贡献多普勒频率 $f_D = 2v/\lambda$。

慢时间维的相位斜率是

$$
\varphi'(i) = -2\pi D(f)T_r,\qquad D(f) = \frac{2v}{c}(f_c+f) \tag{4}
$$

$D(f)$ 随 $f$ 变化，带内两端相差 $\dfrac{2vB}{c}$：各频率分量在慢时间上"跑"的速度不同，直接做慢时间 FFT 无法同相积累，这就是**距离-多普勒耦合**。

走动量与跨单元数：

$$
\Delta R = v\,T_{CPI} = vNT_r,\qquad L = \frac{\Delta R}{\rho_r} = \frac{vNT_r}{\rho_r} \tag{5}
$$

工程判据：$L \lesssim 0.5$ 可忽略；$L \gtrsim 2$ 必须校正，否则单个距离单元上的峰值损失约 $20\lg L$ dB。

（这一步在距离多普勒算法里对应 RCMC，可对照《[小斜视角下的距离多普勒算法](/radar/10_RDA_小斜视角/)》。）

## 3 Keystone 变换
引入一个随频率缩放的新慢时间变量：

$$
i = \alpha(f)\,n,\qquad \alpha(f) = \frac{f_c}{f_c+f} \tag{6}
$$

它的作用只有一件事——把 $(f+f_c)\cdot i$ 变成与 $f$ 无关的常数：

$$
(f+f_c)\cdot i = (f+f_c)\cdot\frac{f_c}{f_c+f}\cdot n = f_c\,n \tag{7}
$$

把式(6)代入式(3)：

$$
Y(f,n) = \text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\cdot\exp\left[-j2\pi f_c\frac{2v\,nT_r}{c}\right] \tag{8}
$$

对比式(3)与式(8)：

*   第一个指数项不变：目标的位置信息没有被破坏。
*   随慢时间变化的相位变成 $-2\pi f_c\dfrac{2v}{c}nT_r$，**不含 $f$**：带内所有频率分量的斜率一致，慢时间 FFT 同相聚焦。

变换后每个 $f$ 上的等效慢时间采样间隔变成 $\alpha(f)T_r$，随频率略有不同——矩形采样网格被剪切成楔形，这就是 Keystone 这个名字的来源。

**适用边界。**
*   只对线性走动（匀速）严格成立；有加速度时式(1)多出 $i^2$ 项，走动为抛物线，需另做补偿。
*   要求慢时间序列带限，否则式(9)的插值重建不成立。
*   尺度因子只依赖 $f$ 与 $f_c$，与目标参数无关，因此**免参数**，多目标可同时校正。

## 4 离散实现
$\alpha(f)\,n$ 一般不是整数，而 $X(f,i)$ 只在整数 $i$ 上有定义，所以这一步是分数位置的重采样。

**做法一：sinc 插值。** 带限信号由样本唯一决定，重建核是 sinc：

$$
Y(f,n) = \sum_{i=0}^{N-1} X(f,i)\cdot\text{sinc}\left(\alpha(f)\,n - i\right),\qquad \text{sinc}(x) = \frac{\sin \pi x}{\pi x} \tag{9}
$$

*   工程上取目标位置前后各 3~4 个点（共 6~8 点）加权，并对截断核加 Kaiser 窗抑制吉布斯振铃。
*   $\alpha > 1$（对应 $f<0$ 的半边）时需要观测窗外的样本：补零或按周期延拓，二者在数据两端略有差别。

**做法二：DFT-IFFT。** 把尺度变换搬到多普勒域，分两步：

$$
X\left(f,\frac{\gamma}{\alpha}\right) = \sum_{i=0}^{N-1} X(f,i)\exp\left(-j2\pi\frac{\gamma i}{N\alpha(f)}\right),\qquad \gamma = 0,1,\dots,N-1 \tag{10}
$$

$$
Y(f,n) = \frac{1}{N\alpha(f)}\sum_{\gamma=0}^{N-1} X\left(f,\frac{\gamma}{\alpha}\right)\exp\left(+j2\pi\frac{\gamma n}{N}\right),\qquad n = 0,1,\dots,N-1 \tag{11}
$$

*   式(10)的核里含 $\alpha(f)$，套不上 FFT 的蝶形结构，只能直接算，$O(N^2)$。
*   式(11)是标准 IFFT。
*   $1/(N\alpha)$ 来自换元时频率轴的伸缩，漏掉会让幅度随 $f$ 出现台阶，等效于在距离维偷偷加窗。

式(10)(11)合起来等价于 $\sum_i X(f,i)\,D_N\left(n - i/\alpha\right)$（$D_N$ 为 Dirichlet 核），与式(9)是同一件事，只是第二步能用 FFT。

**做法三：CZT。** 式(10)是"在单位圆上按 $1/\alpha(f)$ 的角间隔采样 $z$ 变换"，它是 Chirp-Z 变换（CZT）的一个特例，对应参数

$$
A = 1,\qquad W = \exp\left(-j\frac{2\pi}{N\alpha(f)}\right),\qquad M = N \tag{12}
$$

代入 CZT 的通用形式即得式(10)，于是这一步也能用 FFT 实现，每列复杂度由 $O(N^2)$ 降到 $O(N\log N)$。CZT 的定义、Bluestein 分解、FFT 实现与 $A,W,M$ 的取法见《[Chirp-Z 变换（CZT）](/radar/11_Chirp-Z变换/)》。

| 实现 | 数值性质 | 每列复杂度 | 备注 |
| :--- | :--- | :--- | :--- |
| 截断 sinc 插值 | 理想插值的近似 | $O(QN)$，$Q$ 为核长 | 最简单，注意边界 |
| 全 sinc 插值 | 与 DFT-IFFT 等价 | $O(N^2)$ | 慢 |
| DFT-IFFT | 精确（周期 sinc） | $O(N^2)$ | 隐含周期延拓 |
| CZT | 与 DFT-IFFT 等价 | $O(N\log N)$ | 脉冲数大时首选 |

## 5 多普勒模糊与补偿
慢时间以 $T_r$ 采样，无模糊多普勒范围只有 $\pm f_r/2$；而真实的多普勒量 $D(f)$ 可以超出它，超出部分折叠：

$$
D(f) = k\,f_r + f_a,\qquad \lvert f_a\rvert \le \frac{f_r}{2} \tag{13}
$$

$k$ 是整数，即**模糊数**。关键一步：在整数脉冲序号上

$$
\exp\left(-j2\pi k f_r\,iT_r\right) = \exp\left(-j2\pi ki\right) \equiv 1 \tag{14}
$$

**模糊部分在样本上完全不可见**，所以插值重建出来的是 $f_a$ 而不是 $D(f)$，插值后的相位斜率仍然含 $f$：

$$
-2\pi\,\alpha(f)\,f_a T_r \tag{15}
$$

带内两端相差约 $B/f_c$，累积到 $N$ 个脉冲可达若干 $\pi$，最后沿距离维求和时相互抵消。因此在插值结果上补一项：

$$
Y(f,n) \leftarrow Y(f,n)\cdot\exp\left(-j2\pi k\,\alpha(f)\,n\right) \tag{16}
$$

补偿后的斜率为

$$
-2\pi\,\alpha(f)\,(k f_r + f_a)\,T_r = -2\pi\,\alpha(f)\,D(f)\,T_r = -2\pi f_c\frac{2v}{c}T_r \tag{17}
$$

与 $f$ 无关，回到式(8)的理想结果。

*   $k = 0$（低速或高 PRF）时补偿项恒为 1，直接跳过。
*   补偿必须放在插值**之后**：插值前数据只在整数点上，$\left.\exp\left(-j2\pi k\alpha n\right)\right\rvert _{i=\alpha n} = \exp\left(-j2\pi ki\right) = 1$，乘了等于没乘。
*   $k$ 的来源：多 PRF 解模糊、先验速度，或对 $k$ 盲搜索（取积累峰值最大者）。

## 6 工程判据
*   **是否需要**：由式(5)算出 $L$，$L \lesssim 0.5$ 可不做，$L \gtrsim 2$ 必须做。
*   **参数选择**：插值核 4~8 点加窗；$N$ 小用截断 sinc、$N$ 大用 CZT；只处理 $\lvert f\rvert \le B/2$，带边留几个 bin 不参与。
*   **怎么检查做对了**：把每列的峰值位置画出来，校正前是一条斜线、校正后应变成水平线；RD 图峰值提升应接近 $20\lg L$ dB；静止目标校正前后应基本不变。

## 7 速查

$$
\tau_i = \frac{2(R_0+v\,iT_r)}{c},\qquad X(f,i) = \text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\tau_i\right]
$$

$$
\alpha(f) = \frac{f_c}{f_c+f},\quad i = \alpha(f)\,n
\qquad\Longrightarrow\qquad
Y(f,n) = \text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\exp\left[-j2\pi f_c\frac{2v\,nT_r}{c}\right]
$$

$$
Y(f,n) = \sum_{i} X(f,i)\,\text{sinc}\left(\alpha n - i\right)
\qquad
Y(f,n) = \frac{1}{N\alpha}\sum_{\gamma} X\left(f,\frac{\gamma}{\alpha}\right)\exp\left(+j2\pi\frac{\gamma n}{N}\right)
$$

$$
k \ne 0:\qquad Y(f,n) \leftarrow Y(f,n)\cdot\exp\left(-j2\pi k\,\alpha(f)\,n\right)
$$
