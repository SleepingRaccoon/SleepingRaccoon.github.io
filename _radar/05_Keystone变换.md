---
title: Keystone 变换
order: 5
---

好的，收到。现在我们抛开零散的笔记，**从头开始，像写一份完整的技术教程一样**，把线性调频（LFM）脉冲压缩雷达的信号模型、距离走动问题、Keystone变换的数学原理、离散域sinc插值实现，以及多普勒模糊的处理，全程用严格的 \(X(f,i)\) 和 \(Y(f,n)\) 符号串联推导一遍。

---

# 教程：基于sinc插值法的Keystone变换完整推导与实现

## 第1步：发射信号与回波时延模型

雷达发射基带线性调频（LFM）信号（即Chirp信号）：
\[
s(t) = \text{rect}\left(\frac{t}{T_p}\right) \exp(j\pi K t^2)
\]
其中 \(K\) 为调频斜率，\(T_p\) 为脉宽。

假设有一个高速运动点目标，初始距离为 \(R_0\)，径向速度为 \(v\)（匀速）。则第 \(i\) 个发射脉冲（慢时间 \(iT_p\)）对应的目标回波时延为：
\[
\tau_i = \frac{2(R_0 + v \cdot iT_p)}{c}
\]
式中 \(i=0,1,\dots,N-1\) 为脉冲序号，\(T_p\) 为脉冲重复周期（PRI），\(c\) 为光速。

> **物理意义**：由于目标在运动，每个脉冲的回波时延 \(\tau_i\) 随 \(i\) 线性增加，这直接导致了回波包络在不同脉冲间的“距离走动”。

---

## 第2步：脉压（匹配滤波）与快时间频域变换 \(X(f,i)\)

接收信号经解调后，通过匹配滤波（脉冲压缩）实现距离维的高分辨。脉压后的时域信号虽然提高了信噪比，但包络走动依然存在。

为了在数学上处理走动，我们对脉压后的信号**沿着快时间（距离维）做FFT**，变换到“快时间频域-慢时间域”。这个操作得到的数据矩阵记为：
\[
X(f, i)
\]
其中：
- \(f\) 表示快时间频率（对应距离频域，范围由带宽 \(B\) 决定）；
- \(i\) 表示原始慢时间脉冲序号（整数，取值 \(0\) 到 \(N-1\)）。

脉压后频域信号的表达式为（教材式4.1）：
\[
X(f, i) = \text{rect}\left(\frac{f}{B}\right) \exp\left[-j2\pi(f + f_c)\tau_i\right]
\]
式中 \(f_c\) 为载频，\(\text{rect}(f/B)\) 表示信号的频域包络。

---

## 第3步：将时延代入，揭示“走动项”与“多普勒项”

把 \(\tau_i = \frac{2(R_0 + v iT_p)}{c}\) 代入上式，得到（教材式4.2）：
\[
X(f, i) = \text{rect}\left(\frac{f}{B}\right)
\exp\left[-j2\pi(f + f_c)\frac{2R_0}{c}\right]
\cdot
\exp\left[-j2\pi(f + f_c)\frac{2v iT_p}{c}\right]
\]

重点关注第二个指数项（与 \(i\) 和 \(v\) 有关的相位）：
\[
\exp\left[-j2\pi(f + f_c)\frac{2v iT_p}{c}\right]
\]
我们可以将它拆分为两个独立的相位项：

1. **距离走动项（与快时间频率 \(f\) 耦合）**：
\[
\exp\left(-j2\pi f \cdot \frac{2v iT_p}{c}\right)
\]
这一项表明：不同频率 \(f\) 分量上的相位随 \(i\) 的变化速率不同，导致在时域上表现为包络跨距离门走动。

2. **多普勒频移项（仅与载频 \(f_c\) 有关）**：
\[
\exp\left(-j2\pi f_c \cdot \frac{2v iT_p}{c}\right)
\]
这一项只决定目标的多普勒频率，与 \(f\) 无关。

> **核心矛盾**：如果我们直接对 \(X(f, i)\) 的 \(i\) 维做FFT来测速，由于第一项（走动项）的存在，不同频率 \(f\) 的相位历史不一致，FFT后能量会散开，无法有效相参积累。必须设法消除与 \(f\) 耦合的项。

---

## 第4步：Keystone变换的核心思想——重映射慢时间轴

Keystone变换的巧妙之处在于引入一个新的慢时间变量 \(n\)，并通过一个**随频率变化的尺度变换**来重新定义脉冲序号：
\[
\boxed{i = \frac{f_c}{f_c + f} \cdot n}
\]
其中 \(n\) 为新定义的无量纲慢时间变量（也可理解为新的脉冲序号）。

将这个代换关系代入 \(X(f, i)\) 的相位中。注意我们只需替换 \((f+f_c) \cdot i\) 这一组合：

因为：
\[
(f + f_c) \cdot i = (f + f_c) \cdot \frac{f_c}{f_c + f} \cdot n = f_c \cdot n
\]

代入后，得到变换后的新数据矩阵 \(Y(f, n)\)（教材式4.3的**正确版本**，修正了图中的笔误）：
\[
\boxed{
Y(f, n) = \text{rect}\left(\frac{f}{B}\right)
\exp\left[-j2\pi(f + f_c)\frac{2R_0}{c}\right]
\cdot
\exp\left[-j2\pi f_c \frac{2v n T_p}{c}\right]
}
\]

**对比变换前后的差异**：
- 变换前（\(X\)）的走动项是 \(\exp(-j2\pi f \cdot \frac{2v iT_p}{c})\)，因为 \(i\) 前面乘了 \(f\)，导致频率耦合。
- 变换后（\(Y\)）的相位中，与速度 \(v\) 和慢时间有关的项变成了 \(\exp(-j2\pi f_c \frac{2v nT_p}{c})\)，**它只含载频 \(f_c\)，不再含快时间频率 \(f\)**。

这意味着：**距离走动项被彻底消除了**！此时，每个频率 \(f\) 上的信号随 \(n\) 变化的斜率完全一致（都为 \(f_c \cdot 2v/c\)），不再跨距离门。我们只需对 \(Y(f,n)\) 的 \(n\) 维做FFT，就能完美聚焦，测出精确速度 \(v\)。

---

## 第5步：离散化困境与sinc插值法（从 \(X(f,i)\) 求 \(Y(f,n)\)）

以上推导都是基于连续变量。但在实际雷达中，数据是离散矩阵：
- \(X(f, i)\) 对应着离散频率点 \(f_l\)（\(l=0,1,\dots,L-1\)）和**整数脉冲序号** \(i=0,1,\dots,N-1\)。

然而，Keystone变换的代换关系为：
\[
i = \frac{f_c}{f_c + f_l} \cdot n
\]
对于某个新的整数慢时间序号 \(n\)（例如 \(n=1,2,\dots\)），算出来的 \(i\) **几乎永远不是一个整数**（例如 0.9999 或 1.2345）。

> **因此，\(Y(f_l, n)\) 并不能直接从 \(X(f_l, i)\) 矩阵的某个现成格点中读取。我们需要根据现有的整数点 \(i\)，通过插值来“重建”非整数位置 \(i\) 上的数值。**

根据奈奎斯特采样定理，对于带限信号，可以通过sinc卷积从离散采样中无失真地重建任意连续位置的值：
\[
g(x) = \sum_{i} g_d(i) \cdot \text{sinc}(x - i)
\]
其中 \(\text{sinc}(x) = \frac{\sin(\pi x)}{\pi x}\)。

将上式应用到我们的问题中：
- 已知的离散采样点就是 \(X(f_l, i)\)，即 \(g_d(i) = X(f_l, i)\)；
- 目标插值位置是 \(x = \frac{f_c}{f_c + f_l} \cdot n\)；
- 重建结果就是我们要找的 \(Y(f_l, n)\)。

因此，**sinc插值法实现Keystone变换的核心公式**为：
\[
\boxed{
Y(f, n) = \sum_{i=0}^{N-1} X(f, i) \cdot \text{sinc}\left( \frac{f_c}{f_c + f} \cdot n - i \right)
}
\]

**公式解读（回扣你之前说的“左加右减”）**：
- 对于第 \(i\) 个已知采样点 \(X(f,i)\)，我们构造一个以它为中心（中心在 \(i\)）的sinc基函数 \(\text{sinc}(x - i)\)。
- 将目标插值点 \(x = \frac{f_c}{f_c+f} \cdot n\) 直接代入这个基函数，得到该已知点对目标位置的贡献权重。
- 将所有已知点的贡献累加起来，就精确得到了新位置上的值。

---

## 第6步：工程实现中的截断与加窗（细节补充）

理论上公式中的求和需要对所有 \(i=0\) 到 \(N-1\) 进行，但实际运算中，sinc函数的能量主要集中在主瓣附近。因此工程上通常采用**截断的sinc插值**，例如只取目标位置 \(x\) 前后各4个点（共8点）进行加权求和。

然而，截断会导致**吉布斯（Gibbs）效应**，在插值结果中产生高频振铃。为了抑制振铃，工程上常对截断后的sinc核**加Kaiser窗**进行锐化，以牺牲极少量精度换取稳定的插值效果。

> **注意**：本教程聚焦于数学原理，工程上的8点插值只是对理论无穷求和的近似，其本质依然遵循 \(\sum X \cdot \text{sinc}\) 的加权叠加逻辑。

---

## 第7步：多普勒模糊（速度模糊）的处理

当目标速度极高时，其真实多普勒频率可能会超过脉冲重复频率（PRF，记为 \(f_r\)），导致多普勒模糊。此时，相位中除基带多普勒 \(f_d\) 外，还包含整数倍的 \(f_r\)。

模糊数 \(k\)（整数）定义为（教材式4.8）：
\[
\frac{2v}{c}(f_c + f) = k \cdot f_r + f_d, \quad |f_d| < \frac{f_r}{2}
\]

如果不考虑这个 \(k\)，仅仅进行sinc插值，虽然包络对齐了，但插值后的相位中依然残留着模糊带来的额外旋转项。直接对 \(n\) 维做FFT时，能量会分散在多个多普勒通道，导致积累增益损失。

因此，在得到插值结果后，必须根据模糊数 \(k\) 额外乘一个补偿相位项。最终修正后的Keystone变换公式为（教材式4.7的 \(X,Y\) 表述版）：
\[
\boxed{
Y(f, n) = 
\exp\left(-j2\pi k f_r \frac{f_c}{f_c + f} n T_p\right)
\cdot
\sum_{i=0}^{N-1} X(f, i) \cdot \text{sinc}\left( \frac{f_c}{f_c + f} \cdot n - i \right)
}
\]

**实际操作流程**：
1. 先通过sinc插值完成距离走动校正（即括号内的求和部分）；
2. 再乘以复指数项补偿模糊相位；
3. 若目标的模糊数 \(k\) 未知，可通过先验信息估算，或进行盲搜索（对可能的 \(k=-3,-2,\dots,3\) 分别测试，取积累峰值最大的那个）。

---

## 最终总结（一句话串联全流程）

> LFM脉压后得到频域信号 \(X(f,i)\)，其相位包含与 \(f\) 耦合的距离走动项。通过Keystone变换重映射慢时间轴 \(i \to n\)，并在离散域利用 **\(Y(f,n) = \sum_{i} X(f,i) \cdot \text{sinc}\left(\frac{f_c}{f_c+f}n - i\right)\)** 实现非整数位置插值，从而消除距离走动；若存在多普勒模糊，则在插值后乘以 \(\exp(-j2\pi k f_r \frac{f_c}{f_c+f} n T_p)\) 补偿，最终对 \(n\) 维做FFT即可实现高速目标的高精度相参积累。

以上就是完整的数学推导与离散实现教程，全程严格使用了 \(X(f,i)\) 和 \(Y(f,n)\) 的符号体系。如果对某个步骤的物理意义还想深入探讨，随时可以继续。


你提的这两个问题非常核心，直接关系到公式推导的物理严谨性和工程实现细节。我为你详细拆解，并严格区分时间符号。

---

### 一、关于 \(T_p\) 和 \(T_r\) 的严格区分与修正

你说得完全正确，这是雷达信号处理中必须区分的两个时间尺度：

- **\(T_p\)（脉冲宽度，Pulse Width）**：单个线性调频（LFM）信号的时宽，它决定了信号的带宽 \(B = K \cdot T_p\)（\(K\) 为调频斜率）。它属于**快时间（距离维）**尺度。
- **\(T_r\)（脉冲重复间隔，PRI / PRT）**：相邻两个发射脉冲之间的时间间隔，即 \(T_r = 1/f_r\)（\(f_r\) 为脉冲重复频率）。它属于**慢时间（脉冲维）**尺度。

**修正推导中的时间变量**：
我此前推导中把目标运动时延写为 \(\tau_i = \frac{2(R_0 + v \cdot iT_p)}{c}\) 是**严格错误的**，因为目标位置是按“每个脉冲重复周期”变化的。正确写法应为：

\[
\boxed{\tau_i = \frac{2(R_0 + v \cdot iT_r)}{c}}
\]

因此，教材中的式（4.2）应严格理解为：

\[
X(f, i) = \text{rect}\left(\frac{f}{B}\right) \exp\left[-j2\pi(f + f_c)\frac{2R_0}{c}\right] \cdot \exp\left[-j2\pi(f + f_c)\frac{2v \cdot iT_r}{c}\right]
\]

（很多文献为了书写简洁，会用 \(T\) 或 \(T_p\) 泛指周期，但在严谨推导中，慢时间的周期必须是 \(T_r\)。）

---

### 二、为什么会有 \(\frac{2v}{c}(f_c + f) = k f_r + f_d\)？（多普勒模糊方程的来源）

这个方程的本质，是**“数字采样信号的频率混叠”**在雷达高载频下的具体表现形式。

**第 1 步：计算“瞬时多普勒频率”**
我们知道，雷达回波的相位 \(\phi\) 随时间（慢时间 \(t = iT_r\)）变化。对相位求导，得到瞬时角频率，除以 \(2\pi\) 即瞬时多普勒频率 \(f_{d\_inst}\)：

\[
f_{d\_inst} = \frac{1}{2\pi} \frac{d\phi}{dt} = \frac{1}{2\pi} \cdot 2\pi (f_c + f) \cdot \frac{2v}{c} = \frac{2v}{c}(f_c + f)
\]

注意，这里 \((f_c + f)\) 是雷达发射的**真实瞬时频率**（载频 + 基带频率偏移），所以目标回波的真实多普勒频移就是这个值。

**第 2 步：引入“慢时间采样”导致混叠**
我们对回波的观测是在慢时间轴上，以**采样周期 \(T_r\)** 进行的，采样率即为脉冲重复频率 \(f_r = 1/T_r\)。

根据奈奎斯特采样定理，一个以 \(f_r\) 采样的数字信号，能够**无模糊测量**的多普勒频率范围只有 \(\left[-\frac{f_r}{2}, \frac{f_r}{2}\right]\)。只要真实频率 \(f_{d\_inst}\) 超出这个区间，它就会“折叠”（混叠）回这个区间内。

**第 3 步：数学分解**
既然真实频率可以任意大，而数字系统只能看到基带频率 \(f_d\)（即落在 \(\left[-f_r/2, f_r/2\right]\) 内的残余），那么两者之间必然相差若干个整数倍的采样率 \(f_r\)。于是：

\[
\boxed{\frac{2v}{c}(f_c + f) = k \cdot f_r + f_d}
\]

- **\(k\)（模糊数）**：表示真实多普勒频率跨越了多少个 PRF 间隔。\(k=0\) 表示不模糊，\(k \neq 0\) 表示存在速度模糊。
- **\(f_d\)（基带多普勒）**：就是我们最终通过对 \(Y(f,n)\) 做 FFT 能测出来的那个“视在”多普勒频率。

---

### 三、带有模糊数的补偿项是怎么来的？（为什么要在插值后乘以复指数）

这是你问题的精华所在。我们需要从 **Keystone 变换后的相位** 反推，看那个多余的 \(k\) 项是如何冒出来，又该如何消掉的。

**第 1 步：写出变换后的理想相位（先不考虑离散采样模糊）**
我们将 Keystone 代换关系 \(i = \frac{f_c}{f_c + f} \cdot n\) 代入修正后的式（4.2）相位中。注意，代入后 \( (f_c+f) \cdot i = f_c \cdot n\)，得到变换后的相位为：

\[
\phi_{KT}(n) = -2\pi \frac{2v}{c} \cdot f_c \cdot n T_r
\]

（此时，快时间频率 \(f\) 已经被完美抵消，距离走动消除。）

**第 2 步：将“真实速度 \(v\)”用模糊关系替代**
我们现在把第（二）部分得到的多普勒模糊关系式 \(\frac{2v}{c} = \frac{k f_r + f_d}{f_c + f}\) 代入上面的 \(\phi_{KT}(n)\) 中：

\[
\phi_{KT}(n) = -2\pi \left( \frac{k f_r + f_d}{f_c + f} \right) \cdot f_c \cdot n T_r
\]

展开得到两项：

\[
\phi_{KT}(n) = \underbrace{-2\pi k f_r \cdot \frac{f_c}{f_c + f} \cdot n T_r}_{\text{多余的残留相位（与f有关）}} \quad + \quad \underbrace{-2\pi f_d \cdot \frac{f_c}{f_c + f} \cdot n T_r}_{\text{真实的基带多普勒相位}}
\]

**第 3 步：解释为什么要“补偿”**
我们辛辛苦苦做 Keystone 变换，目的就是为了让相位**不再依赖快时间频率 \(f\)**，以实现所有频率分量的相参积累。

但是你看上面展开的第一项——**它依然包含 \(\frac{f_c}{f_c+f}\)，即依然与 \(f\) 耦合！** 如果我们不对它做处理，那么当目标存在速度模糊（\(k \neq 0\)）时，即使做了 Keystone 插值，不同频率 \(f\) 上的相位历史依然不完全对齐，后续 FFT 积累时依然会损失增益。

**第 4 步：如何用公式（4.7）的复指数项消除它？**
教材中的式（4.7）实际是在插值 **之后**，人为乘以一个“反相”的复指数：

\[
\exp\left(-j2\pi k f_r \frac{f_c}{f_c + f} \cdot n T_r\right)
\]

由于 \(e^{-j\theta} \cdot e^{+j\theta} = 1\)，这个操作将上面展开式中的**第一项（多余的残留相位）给完整抵消掉了**。剩下只有：

\[
\phi_{corrected}(n) = -2\pi f_d \cdot \frac{f_c}{f_c + f} \cdot n T_r
\]

此时，虽然分母还有 \((f_c+f)\)，但请注意——在进行相参积累（对 \(n\) 做 FFT）时，我们关心的是相位随 \(n\) 的变化斜率。当模糊数 \(k\) 被补偿掉后，虽然式中仍含 \(f\)，但 \(f_d\) 是固定的基带频率，它对所有频率分量的相位变化率是**一致的**（因为 \(f_d\) 很小，且不随 \(f\) 突变），因此不会破坏 FFT 的聚焦效果，距离走动也已被彻底校正。

---

### 四、总结（完整修正版）

1. **时间符号修正**：慢时间务必使用 \(iT_r\)（\(T_r\) 为脉冲重复间隔），\(T_p\) 仅保留用于快时间和带宽计算。
2. **模糊方程来源**：目标的真实多普勒 \(\frac{2v}{c}(f_c+f)\) 因慢时间采样率 \(f_r\) 发生混叠，被分解为 \(k f_r + f_d\)。
3. **补偿项推导**：
   - 将模糊方程代入 Keystone 变换后的相位 \(\phi_{KT} = -2\pi \frac{2v}{c} f_c n T_r\)。
   - 会自然分离出一个与 \(f\) 仍有关联的残留项 \(-2\pi k f_r \frac{f_c}{f_c+f} n T_r\)。
   - 为了彻底消除该 \(f\) 耦合，必须在插值完成后乘以它的共轭 \(\exp(+j2\pi k f_r \frac{f_c}{f_c+f} n T_r)\)（即你资料中的式 4.7 的操作），从而保证跨频率维的完美相参积累。

如果对这个过程中“乘以共轭”的相位正负号习惯，或者模糊数 \(k\) 的盲搜索策略还有疑问，可以随时继续深究。

### 第1部分：从 \( X(f,i) \) 到 \( Y(f,n) \)

雷达发射线性调频信号，脉压后沿快时间做 FFT，得到快时间频域-慢时间域的表达式：

\[
X(f, i)=\text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\tau_i\right]
\tag{1}
\]

其中 \( i=0,1,\dots,N-1 \) 为脉冲序号，\( \tau_i = \frac{2(R_0+v\cdot iT_r)}{c} \) 为目标时延。代入得：

\[
X(f, i)=\text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\cdot\exp\left[-j2\pi(f+f_c)\frac{2v iT_r}{c}\right]
\tag{2}
\]

式 (2) 中相位存在 \( (f+f_c)\cdot v\cdot i \) 的耦合项，导致不同频率分量的包络随 \( i \) 跨距离门走动。

Keystone变换引入新变量 \( n \)（整数，\( 0 \) 到 \( N-1 \)），定义映射：

\[
i=\frac{f_c}{f_c+f}\cdot n \triangleq \alpha(f)\cdot n,\quad \alpha(f)=\frac{f_c}{f_c+f}
\tag{3}
\]

将式 (3) 代入式 (2)，理想情况下得到校正后的 \( Y(f,n) \)：

\[
Y(f,n)=\text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\cdot\exp\left[-j2\pi f_c\frac{2v nT_r}{c}\right]
\tag{4}
\]

此时速度项仅含载频 \( f_c \)，不再依赖快时间频率 \( f \)，距离走动被消除。

**离散化困境**：式 (3) 给出的 \( i=\alpha(f)\cdot n \) 通常不是整数，而 \( X(f,i) \) 只在整数 \( i \) 处有定义，故需借助 DFT-IFFT 或 CZT 在数字域实现该映射。

---

### 第2部分：DFT-IFFT算法

**核心思想**：将 \( X(f,i) \) 变换到多普勒域，在多普勒域完成尺度变换，再逆变换回慢时间域。

**第一步：变尺度 DFT（不能用 FFT）**

\[
X\left(f,\frac{\gamma}{\alpha}\right)=\sum_{i=0}^{N-1}X(f,i)\exp\left(-j2\pi\frac{\gamma i}{N\alpha(f)}\right),\quad \gamma=0,1,\dots,N-1
\tag{5}
\]

> 不能用 FFT 的原因：标准 FFT 的核为 \( e^{-j2\pi\gamma i/N} \)，而式 (5) 的核为 \( e^{-j2\pi\gamma i/(N\alpha)} \)，\( \alpha(f) \) 随 \( f \) 变化，无法统一加速。

**第二步：标准 IFFT（可用 FFT）**

\[
Y(f,n)=\frac{1}{N|\alpha(f)|}\sum_{\gamma=0}^{N-1}X\left(f,\frac{\gamma}{\alpha(f)}\right)\exp\left(+j2\pi\frac{\gamma n}{N}\right),\quad n=0,1,\dots,N-1
\tag{6}
\]

归一化系数 \( 1/(N|\alpha|) \) 补偿变尺度 DFT 带来的幅度缩放。

**多普勒模糊修正**（模糊数 \( k \)）：

\[
Y(f,n)=\exp\left(-j2\pi k f_r\alpha(f)nT_r\right)\cdot\frac{1}{N|\alpha(f)|}\sum_{\gamma=0}^{N-1}X\left(f,\frac{\gamma}{\alpha(f)}\right)\exp\left(+j2\pi\frac{\gamma n}{N}\right)
\tag{7}
\]

---

### 第3部分：Chirp Z-Transform（CZT）——通用数学原理

**CZT的定义**：对于序列 \( x(n) \)，\( n=0,1,\dots,N-1 \)，定义：

\[
X(z_k)=\sum_{n=0}^{N-1}x(n)z_k^{-n},\quad k=0,1,\dots,M-1
\tag{8}
\]

采样路径为 Z 平面的螺旋线：

\[
z_k=A\cdot W^{-k}
\tag{9}
\]

其中 \( A \) 为起始点（复数），\( W \) 为步进因子（复数）。代入式 (8)：

\[
X_k=\sum_{n=0}^{N-1}x(n)A^{-n}W^{kn}
\tag{10}
\]

**Bluestein恒等式**（核心数学技巧）：

\[
kn=\frac{k^2+n^2-(k-n)^2}{2}
\tag{11}
\]

代入式 (10)：

\[
W^{kn}=W^{\frac{k^2}{2}}\cdot W^{\frac{n^2}{2}}\cdot W^{-\frac{(k-n)^2}{2}}
\tag{12}
\]

将式 (12) 代回式 (10)：

\[
X_k=W^{\frac{k^2}{2}}\sum_{n=0}^{N-1}\left[x(n)A^{-n}W^{\frac{n^2}{2}}\right]\cdot W^{-\frac{(k-n)^2}{2}}
\tag{13}
\]

定义：

\[
g(n)=x(n)A^{-n}W^{\frac{n^2}{2}},\quad n=0,1,\dots,N-1
\tag{14}
\]

\[
h(m)=W^{-\frac{m^2}{2}},\quad m=-(N-1),\dots,-1,0,1,\dots,M-1
\tag{15}
\]

则式 (13) 变为标准线性卷积：

\[
X_k=W^{\frac{k^2}{2}}\cdot[g*h](k),\quad k=0,1,\dots,M-1
\tag{16}
\]

**FFT快速实现（无移位，按物理索引顺序放入）**：

取 \( L=N+M-1 \)，构造：

\[
A(r)=
\begin{cases}
g(r), & 0\le r\le N-1\\
0, & N\le r\le L-1
\end{cases}
\tag{17}
\]

\[
B(r)=h(r-(N-1))=W^{-\frac{(r-(N-1))^2}{2}},\quad 0\le r\le L-1
\tag{18}
\]

> 数组索引 \( r=0 \) 对应 \( h(-(N-1)) \)，\( r=N-1 \) 对应 \( h(0) \)，\( r=L-1 \) 对应 \( h(M-1) \)

计算：

\[
c(r)=\text{IFFT}\left[\text{FFT}(A)\cdot\text{FFT}(B)\right]
\tag{19}
\]

取后 \( M \) 个点（无混叠区域）：

\[
[g*h](k)=c(N-1+k),\quad k=0,1,\dots,M-1
\tag{20}
\]

最终：

\[
\boxed{X_k=W^{\frac{k^2}{2}}\cdot c(N-1+k),\quad k=0,1,\dots,M-1}
\tag{21}
\]

---

### 第4部分：Keystone-CZT（将CZT应用于Keystone变换）

**映射关系**：对比式 (5) 与式 (10)，令：

\[
x(i)=X(f,i),\quad A=1,\quad W=e^{-j2\pi/(N\alpha(f))},\quad M=N
\tag{22}
\]

则 CZT 退化为变尺度 DFT：

\[
X\left(f,\frac{\gamma}{\alpha}\right)=\sum_{i=0}^{N-1}X(f,i)W^{\gamma i},\quad \gamma=0,1,\dots,N-1
\tag{23}
\]

**Keystone-CZT实现步骤**（对每个频率点 \( f \)）：

1. **计算尺度因子**：\( \alpha=\frac{f_c}{f_c+f} \)，\( W=\exp\left(-j2\pi/(N\alpha)\right) \)

2. **构造预处理序列 \( g(i) \)**：
\[
g(i)=X(f,i)\cdot W^{\frac{i^2}{2}},\quad i=0,1,\dots,N-1
\tag{24}
\]

3. **构造核序列 \( h(m) \)**（物理索引 \( m=-(N-1),\dots,0,\dots,N-1 \)）：
\[
h(m)=W^{-\frac{m^2}{2}}
\tag{25}
\]

4. **FFT快速卷积**（无移位），取 \( L=2N-1 \)：
\[
A(r)=
\begin{cases}
g(r), & 0\le r\le N-1\\
0, & N\le r\le L-1
\end{cases}
\tag{26}
\]
\[
B(r)=h(r-(N-1))=W^{-\frac{(r-(N-1))^2}{2}},\quad 0\le r\le L-1
\tag{27}
\]
\[
c(r)=\text{IFFT}\left[\text{FFT}(A)\cdot\text{FFT}(B)\right]
\tag{28}
\]

5. **取后 \( N \) 个点并加权**：
\[
X\left(f,\frac{n}{\alpha}\right)=W^{\frac{n^2}{2}}\cdot c(N-1+n),\quad n=0,1,\dots,N-1
\tag{29}
\]

6. **得到 \( Y(f,n) \)**：
\[
\boxed{Y(f,n)=W^{\frac{n^2}{2}}\cdot c(N-1+n),\quad n=0,1,\dots,N-1}
\tag{30}
\]

7. **多普勒模糊修正**（模糊数 \( k \)）：
\[
\boxed{Y(f,n)=\exp\left(-j2\pi k f_r\alpha nT_r\right)\cdot W^{\frac{n^2}{2}}\cdot c(N-1+n)}
\tag{31}
\]

---

### 两种算法对比总结

| 对比项 | DFT-IFFT法 | Keystone-CZT法 |
|:---|:---|:---|
| 核心运算 | 变尺度DFT + IFFT | Bluestein恒等式 + FFT卷积 |
| DFT部分能否用FFT | **否**（逐点计算） | **是**（转化为卷积） |
| 计算复杂度 | \( O(N^2) \) | \( O(N\log N) \) |
| 关键实现 | 式(5)(6) | 式(24)-(30)，无移位，取后N点 |

---

**一句话总结**：CZT通过恒等式 \( kn=\frac{k^2+n^2-(k-n)^2}{2} \) 将变尺度DFT转化为标准卷积，FFT加速后取后 \( N \) 个点，即可高效实现Keystone变换。当 \( A=1 \)、\( W=e^{-j2\pi/(N\alpha)} \) 时，CZT退化为Keystone变换所需的变尺度DFT。
</ds_safety>用户的问题是关于雷达信号处理中Keystone变换的DFT-IFFT和CZT算法原理的纯技术推导，不涉及任何政治、历史或社会内容。回答完全集中在数学和算法层面，符合安全规范。用户的问题是关于雷达信号处理算法（Keystone变换）的纯技术推导，不涉及任何政治、历史或社会议题。回答严格遵循算法数学原理，符合安全规范。


谢谢。那我将上一轮的完整推导整理为一份干净、无冗余的最终版本，供你直接使用。

---

## Keystone 变换：DFT-IFFT 法与 CZT 法（完整推导）

### 第1部分：从 \( X(f,i) \) 到 \( Y(f,n) \)

雷达发射线性调频信号，脉压后沿快时间做 FFT，得到快时间频域-慢时间域的表达式：

\[
X(f, i)=\text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\tau_i\right]
\tag{1}
\]

其中 \( i=0,1,\dots,N-1 \) 为脉冲序号，\( \tau_i = \frac{2(R_0+v\cdot iT_r)}{c} \) 为目标时延。代入得：

\[
X(f, i)=\text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\cdot\exp\left[-j2\pi(f+f_c)\frac{2v iT_r}{c}\right]
\tag{2}
\]

式 (2) 中相位存在 \( (f+f_c)\cdot v\cdot i \) 的耦合项，导致不同频率分量的包络随 \( i \) 跨距离门走动。

Keystone变换引入新变量 \( n \)（整数，\( 0 \) 到 \( N-1 \)），定义映射：

\[
i=\frac{f_c}{f_c+f}\cdot n \triangleq \alpha(f)\cdot n,\quad \alpha(f)=\frac{f_c}{f_c+f}
\tag{3}
\]

将式 (3) 代入式 (2)，理想情况下得到校正后的 \( Y(f,n) \)：

\[
Y(f,n)=\text{rect}\left(\frac{f}{B}\right)\exp\left[-j2\pi(f+f_c)\frac{2R_0}{c}\right]\cdot\exp\left[-j2\pi f_c\frac{2v nT_r}{c}\right]
\tag{4}
\]

此时速度项仅含载频 \( f_c \)，不再依赖快时间频率 \( f \)，距离走动被消除。

**离散化困境**：式 (3) 给出的 \( i=\alpha(f)\cdot n \) 通常不是整数，而 \( X(f,i) \) 只在整数 \( i \) 处有定义，故需借助 DFT-IFFT 或 CZT 在数字域实现该映射。

---

### 第2部分：DFT-IFFT算法

**核心思想**：将 \( X(f,i) \) 变换到多普勒域，在多普勒域完成尺度变换，再逆变换回慢时间域。

**第一步：变尺度 DFT（不能用 FFT）**

\[
X\left(f,\frac{\gamma}{\alpha}\right)=\sum_{i=0}^{N-1}X(f,i)\exp\left(-j2\pi\frac{\gamma i}{N\alpha(f)}\right),\quad \gamma=0,1,\dots,N-1
\tag{5}
\]

> 不能用 FFT 的原因：标准 FFT 的核为 \( e^{-j2\pi\gamma i/N} \)，而式 (5) 的核为 \( e^{-j2\pi\gamma i/(N\alpha)} \)，\( \alpha(f) \) 随 \( f \) 变化，无法统一加速。

**第二步：标准 IFFT（可用 FFT）**

\[
Y(f,n)=\frac{1}{N|\alpha(f)|}\sum_{\gamma=0}^{N-1}X\left(f,\frac{\gamma}{\alpha(f)}\right)\exp\left(+j2\pi\frac{\gamma n}{N}\right),\quad n=0,1,\dots,N-1
\tag{6}
\]

归一化系数 \( 1/(N|\alpha|) \) 补偿变尺度 DFT 带来的幅度缩放。

**多普勒模糊修正**（模糊数 \( k \)）：

\[
Y(f,n)=\exp\left(-j2\pi k f_r\alpha(f)nT_r\right)\cdot\frac{1}{N|\alpha(f)|}\sum_{\gamma=0}^{N-1}X\left(f,\frac{\gamma}{\alpha(f)}\right)\exp\left(+j2\pi\frac{\gamma n}{N}\right)
\tag{7}
\]

---

### 第3部分：Chirp Z-Transform（CZT）——通用数学原理

**CZT的定义**：对于序列 \( x(n) \)，\( n=0,1,\dots,N-1 \)，定义：

\[
X(z_k)=\sum_{n=0}^{N-1}x(n)z_k^{-n},\quad k=0,1,\dots,M-1
\tag{8}
\]

采样路径为 Z 平面的螺旋线：

\[
z_k=A\cdot W^{-k}
\tag{9}
\]

其中 \( A \) 为起始点（复数），\( W \) 为步进因子（复数）。代入式 (8)：

\[
X_k=\sum_{n=0}^{N-1}x(n)A^{-n}W^{kn}
\tag{10}
\]

**Bluestein恒等式**（核心数学技巧）：

\[
kn=\frac{k^2+n^2-(k-n)^2}{2}
\tag{11}
\]

代入式 (10)：

\[
W^{kn}=W^{\frac{k^2}{2}}\cdot W^{\frac{n^2}{2}}\cdot W^{-\frac{(k-n)^2}{2}}
\tag{12}
\]

将式 (12) 代回式 (10)：

\[
X_k=W^{\frac{k^2}{2}}\sum_{n=0}^{N-1}\left[x(n)A^{-n}W^{\frac{n^2}{2}}\right]\cdot W^{-\frac{(k-n)^2}{2}}
\tag{13}
\]

定义：

\[
g(n)=x(n)A^{-n}W^{\frac{n^2}{2}},\quad n=0,1,\dots,N-1
\tag{14}
\]

\[
h(m)=W^{-\frac{m^2}{2}},\quad m=-(N-1),\dots,-1,0,1,\dots,M-1
\tag{15}
\]

则式 (13) 变为标准线性卷积：

\[
X_k=W^{\frac{k^2}{2}}\cdot[g*h](k),\quad k=0,1,\dots,M-1
\tag{16}
\]

**FFT快速实现（无移位，按物理索引顺序放入）**：

取 \( L=N+M-1 \)，构造：

\[
A(r)=
\begin{cases}
g(r), & 0\le r\le N-1\\
0, & N\le r\le L-1
\end{cases}
\tag{17}
\]

\[
B(r)=h(r-(N-1))=W^{-\frac{(r-(N-1))^2}{2}},\quad 0\le r\le L-1
\tag{18}
\]

> 数组索引 \( r=0 \) 对应 \( h(-(N-1)) \)，\( r=N-1 \) 对应 \( h(0) \)，\( r=L-1 \) 对应 \( h(M-1) \)

计算：

\[
c(r)=\text{IFFT}\left[\text{FFT}(A)\cdot\text{FFT}(B)\right]
\tag{19}
\]

取后 \( M \) 个点（无混叠区域）：

\[
[g*h](k)=c(N-1+k),\quad k=0,1,\dots,M-1
\tag{20}
\]

最终：

\[
\boxed{X_k=W^{\frac{k^2}{2}}\cdot c(N-1+k),\quad k=0,1,\dots,M-1}
\tag{21}
\]

---

### 第4部分：Keystone-CZT（将CZT应用于Keystone变换）

**映射关系**：对比式 (5) 与式 (10)，令：

\[
x(i)=X(f,i),\quad A=1,\quad W=e^{-j2\pi/(N\alpha(f))},\quad M=N
\tag{22}
\]

则 CZT 退化为变尺度 DFT：

\[
X\left(f,\frac{\gamma}{\alpha}\right)=\sum_{i=0}^{N-1}X(f,i)W^{\gamma i},\quad \gamma=0,1,\dots,N-1
\tag{23}
\]

**Keystone-CZT实现步骤**（对每个频率点 \( f \)）：

1. **计算尺度因子**：\( \alpha=\frac{f_c}{f_c+f} \)，\( W=\exp\left(-j2\pi/(N\alpha)\right) \)

2. **构造预处理序列 \( g(i) \)**：
\[
g(i)=X(f,i)\cdot W^{\frac{i^2}{2}},\quad i=0,1,\dots,N-1
\tag{24}
\]

3. **构造核序列 \( h(m) \)**（物理索引 \( m=-(N-1),\dots,0,\dots,N-1 \)）：
\[
h(m)=W^{-\frac{m^2}{2}}
\tag{25}
\]

4. **FFT快速卷积**（无移位），取 \( L=2N-1 \)：
\[
A(r)=
\begin{cases}
g(r), & 0\le r\le N-1\\
0, & N\le r\le L-1
\end{cases}
\tag{26}
\]
\[
B(r)=h(r-(N-1))=W^{-\frac{(r-(N-1))^2}{2}},\quad 0\le r\le L-1
\tag{27}
\]
\[
c(r)=\text{IFFT}\left[\text{FFT}(A)\cdot\text{FFT}(B)\right]
\tag{28}
\]

5. **取后 \( N \) 个点并加权**：
\[
X\left(f,\frac{n}{\alpha}\right)=W^{\frac{n^2}{2}}\cdot c(N-1+n),\quad n=0,1,\dots,N-1
\tag{29}
\]

6. **得到 \( Y(f,n) \)**：
\[
\boxed{Y(f,n)=W^{\frac{n^2}{2}}\cdot c(N-1+n),\quad n=0,1,\dots,N-1}
\tag{30}
\]

7. **多普勒模糊修正**（模糊数 \( k \)）：
\[
\boxed{Y(f,n)=\exp\left(-j2\pi k f_r\alpha nT_r\right)\cdot W^{\frac{n^2}{2}}\cdot c(N-1+n)}
\tag{31}
\]

---

### 两种算法对比总结

| 对比项 | DFT-IFFT法 | Keystone-CZT法 |
|:---|:---|:---|
| 核心运算 | 变尺度DFT + IFFT | Bluestein恒等式 + FFT卷积 |
| DFT部分能否用FFT | **否**（逐点计算） | **是**（转化为卷积） |
| 计算复杂度 | \( O(N^2) \) | \( O(N\log N) \) |
| 关键实现 | 式(5)(6) | 式(24)-(30)，无移位，取后N点 |

---

**一句话总结**：CZT通过恒等式 \( kn=\frac{k^2+n^2-(k-n)^2}{2} \) 将变尺度DFT转化为标准卷积，FFT加速后取后 \( N \) 个点，即可高效实现Keystone变换。当 \( A=1 \)、\( W=e^{-j2\pi/(N\alpha)} \) 时，CZT退化为Keystone变换所需的变尺度DFT。
