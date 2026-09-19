---
title: Dechirp 宽带雷达成像：HRRP 与距离-速度耦合
order: 2
description: 从基带回波严格推到 RD 图：参考信号怎么选、共轭相乘的方向、快慢时间 FFT 的近似条件，以及距离-速度耦合项的来源与补偿。
---

这篇把 Dechirp（解线频调）处理从基带回波一路推到 RD 图，重点是那些在简化推导里最容易被跳过的工程边界：参考信号的脉宽与参考距离怎么取、共轭相乘为什么要写成"回波乘参考的共轭"、哪些相位可以忽略、哪些绝对不能忽略，以及距离-速度耦合项从哪来、怎么补偿。

---

## 零、符号约定与基本假设
1. **快时间**：$$\hat{t}$$，**慢时间**：$$t_m$$。
2. **目标运动**：$$R_i(t_m) = R_{i0} + v_i t_m$$，**规定 $$v_i > 0$$ 表示目标远离雷达**（符合雷达界惯例）。
3. **回波时延**：$$\tau_i(t_m) = \frac{2R_i(t_m)}{c}$$。
4. **参考距离**：$$R_{ref}$$，参考时延 $$\tau_{ref} = \frac{2R_{ref}}{c}$$。
5. **相对距离**：$$R_{\Delta i}(t_m) = R_i(t_m) - R_{ref}$$。若目标比参考近，则 $$R_{\Delta i} < 0$$。

---

## 一、精确的基带信号模型

### 1. 发射基带信号

$$
s_t(\hat{t}) = \text{rect}\left(\frac{\hat{t}}{T_p}\right) \exp(j\pi \gamma \hat{t}^2)
$$

### 2. 目标基带回波（保留所有相位）
第 $$i$$ 个散射中心的基带回波为：

$$
s_{ri}(\hat{t}, t_m) = A_i \cdot \text{rect}\left(\frac{\hat{t} - \tau_i(t_m)}{T_p}\right) \exp\left[j\pi \gamma (\hat{t} - \tau_i(t_m))^2\right] \cdot \exp\left[-j2\pi f_c \tau_i(t_m)\right]
$$

*注意：$$\exp[-j2\pi f_c \tau_i(t_m)]$$ 是多普勒效应的唯一来源，必须保留。*

### 3. 参考信号
*   **脉宽**：参考信号脉宽 $$T_{ref}$$ 必须足够大，以覆盖整个接收窗口。通常 $$T_{ref} \ge T_p + \Delta\tau_{max}$$（$$\Delta\tau_{max}$$ 为最大回波时延差）。因此，两个矩形窗相乘后的有效积分时间 $$T_{eff} \approx T_p$$（我们假设 $$T_{ref}$$ 完全覆盖回波窗）。
*   **参考距离限制**：$$R_{ref}$$ 必须选在目标场景中心。如果 $$R_{ref}$$ 偏离目标太远，差频频率 $$f_{if} = \frac{2\gamma}{c}|R_{\Delta i}|$$ 会超出ADC的低通滤波带宽，导致回波被滤除。

$$
s_{ref}(\hat{t}) = \text{rect}\left(\frac{\hat{t} - \tau_{ref}}{T_{ref}}\right) \exp\left[j\pi \gamma (\hat{t} - \tau_{ref})^2\right]
$$

---

## 二、Dechirp 混频与精确相位展开

### 1. 共轭相乘的方向

一个常见的疑问是：为什么不写成 $$s_{ref} \cdot s_r^*$$，那样相位里直接就是 $$R_i - R_{ref}$$，看着更顺？
实际上**标准工程做法是回波乘参考的共轭，即 $$s_r \cdot s_{ref}^*$$**，推导一遍就知道差在哪：

$$
s_{if} = s_r \cdot s_{ref}^* = A_i \cdot \text{rect}(\cdot) \exp\left[j\pi \gamma \left( (\hat{t} - \tau_i)^2 - (\hat{t} - \tau_{ref})^2 \right)\right] \cdot \exp\left[-j2\pi f_c \tau_i\right]
$$

展开相位项：

$$
\Delta \Phi = \pi \gamma \left[ -2\hat{t}\tau_i + \tau_i^2 + 2\hat{t}\tau_{ref} - \tau_{ref}^2 \right] - 2\pi f_c \tau_i
$$

$$
= 2\pi \gamma (\tau_{ref} - \tau_i)\hat{t} + \pi \gamma (\tau_i^2 - \tau_{ref}^2) - 2\pi f_c \tau_i
$$

代入 $$\tau_{ref} - \tau_i = -\frac{2(R_i - R_{ref})}{c} = -\frac{2R_{\Delta i}}{c}$$：

$$
\Delta \Phi = -2\pi \gamma \frac{2R_{\Delta i}}{c} \hat{t} + \pi \gamma (\tau_i^2 - \tau_{ref}^2) - 2\pi f_c \tau_i
$$

**结论**：采用 $$s_r \cdot s_{ref}^*$$，差频频率 $$f_{if} = -\frac{2\gamma}{c} R_{\Delta i}$$。如果目标比参考近（$$R_{\Delta i} < 0$$），$$f_{if} > 0$$，这是一个正频率，方便FFT处理。如果反过来用 $$s_{ref} \cdot s_r^*$$，频率会变成负的，导致频率轴翻转。因此，标准做法是回波乘参考的共轭。

### 2. 常数相位项的展开与忽略条件
令 $$\tau_i = \tau_{ref} + \Delta\tau$$，其中 $$\Delta\tau = \tau_i - \tau_{ref} = \frac{2R_{\Delta i}}{c}$$。

$$
\Phi_{const} = \pi \gamma (\tau_i^2 - \tau_{ref}^2) - 2\pi f_c \tau_i = \pi \gamma (2\tau_{ref}\Delta\tau + \Delta\tau^2) - 2\pi f_c (\tau_{ref} + \Delta\tau)
$$

拆解为四项：
1.  $$\pi \gamma \Delta\tau^2$$：**残余视频相位（RVP）**。
    *   **忽略条件**：当 $$B \Delta\tau \ll 1$$（即相对距离差远小于距离分辨率）时，$$\pi \gamma \Delta\tau^2 = \pi \Delta f \Delta\tau \ll \pi$$，可忽略。
2.  $$2\pi \gamma \tau_{ref} \Delta\tau$$：**距离-速度耦合项**（Dechirp特有）。
    *   **忽略条件**：如果参考距离 $$R_{ref}$$ 不大，且目标速度不高，此项较小。但在高精度成像中**不能忽略**，必须通过算法补偿（即去斜后的残余相位补偿）。
3.  $$-2\pi f_c \tau_{ref}$$：常数项，不影响成像，直接忽略。
4.  $$-2\pi f_c \Delta\tau = -\frac{4\pi}{\lambda} R_{\Delta i}$$：**多普勒相位历史**，**绝对不能忽略**，这是慢时间FFT的核心。

---

## 三、快时间维 FFT（距离维压缩）

对 $$s_{if}(\hat{t}, t_m)$$ 沿快时间 $$\hat{t}$$ 做FFT：

$$
S(f, t_m) = \int s_{if}(\hat{t}, t_m) \exp(-j2\pi f \hat{t}) d\hat{t}
$$

利用矩形窗的傅里叶变换，得到：

$$
S(f, t_m) = \sum_{i=1}^m A_i T_p \text{sinc}\left[ T_p \left( f + \frac{2\gamma R_{\Delta i}(t_m)}{c} \right) \right] \cdot \exp\left[j\Phi_{const}(t_m)\right]
$$

*注意：这里 $$f$$ 是差频频率，峰值位于 $$f = -\frac{2\gamma}{c} R_{\Delta i}(t_m)$$。由于 $$R_{\Delta i}(t_m) = R_{\Delta i0} + v_i t_m$$，峰值频率会随慢时间变化，这就是**距离走动（MTRC）**。*

---

## 四、慢时间维 FFT（多普勒维压缩与 RD 图）

### 1. 展开多普勒相位
将 $$\tau_i(t_m) = \frac{2(R_{i0} + v_i t_m)}{c}$$ 代入 $$\Phi_{const}$$ 的核心项 $$-2\pi f_c \Delta\tau$$：

$$
\Phi_{doppler}(t_m) = -2\pi f_c \frac{2(R_{\Delta i0} + v_i t_m)}{c} = -\frac{4\pi}{\lambda} R_{\Delta i0} - \frac{4\pi v_i}{\lambda} t_m
$$

*   多普勒频率 $$f_{d_i} = -\frac{2v_i}{\lambda}$$。因为 $$v_i > 0$$ 表示远离，多普勒为负，符合物理直觉。

### 2. 忽略耦合项的条件
如果忽略距离-速度耦合项 $$2\pi \gamma \tau_{ref} \Delta\tau$$ 和 RVP，常数相位简化为 $$\Phi_{const}(t_m) \approx -\frac{4\pi}{\lambda} R_{\Delta i0} - \frac{4\pi v_i}{\lambda} t_m$$。

### 3. 慢时间FFT与MTRC
对慢时间 $$t_m$$ 做FFT，得到最终的RD图：

$$
S(f, f_d) = \sum_{i=1}^m A_i T_p T_{CPI} \text{sinc}\left[ T_p \left( f + \frac{2\gamma R_{\Delta i0}}{c} \right) \right] \cdot \text{sinc}\left[ T_{CPI} \left( f_d + \frac{2v_i}{\lambda} \right) \right] \cdot \exp(j\Theta_i)
$$

### 4. 距离走动（MTRC）的忽略条件
在上述推导中，我们假设了在慢时间FFT期间，距离维的sinc峰值没有移动。这要求：

$$
v_i T_{CPI} \ll \rho_r = \frac{c}{2B}
$$

即：**目标在相干处理间隔（CPI）内的运动距离，必须远小于雷达的距离分辨率。**
如果 $$v_i T_{CPI} \ge \rho_r$$，则 $$f = -\frac{2\gamma}{c}(R_{\Delta i0} + v_i t_m)$$ 会导致距离峰随 $$t_m$$ 倾斜，此时不能直接做慢时间FFT，必须先进行**Keystone变换**或**Radon变换**来校正MTRC，否则RD图上的目标会散焦成一条斜线。

---

## 五、最终 RD 图的物理图景

通过上述严格推导，宽带目标的RD图（$$|S(f, f_d)|$$）具有以下特征：

1.  **距离维（横轴 $$f$$）**：由 $$\text{sinc}$$ 函数决定，峰值位于 $$f = -\frac{2\gamma}{c} R_{\Delta i0}$$。目标尺寸 $$> \rho_r$$ 时，沿距离轴展开多个散射中心，形成**高分辨一维距离像（HRRP）**。
2.  **多普勒维（纵轴 $$f_d$$）**：峰值位于 $$f_d = -\frac{2v_i}{\lambda}$$。如果目标为刚体（所有散射中心 $$v_i$$ 相同），多普勒维上所有亮点处于同一高度；如果目标有转动（ISAR成像），不同散射中心的 $$v_i$$ 不同，多普勒维展开，形成**二维几何轮廓**。
3.  **相位 $$\Theta_i$$**：包含残余的RVP、耦合项和初始相位。如果同一距离-多普勒单元内有多个散射中心，复数相加会导致干涉（Glint效应），幅度忽大忽小。
4.  **MTRC效应**：如果 $$v_i T_{CPI} \ge \rho_r$$，RD图上的亮线会倾斜、散焦，必须进行运动补偿。

**总结**：从基带回波出发，经过严格的Dechirp混频（回波乘参考共轭）、快时间FFT（距离压缩）、慢时间FFT（多普勒压缩），宽带目标的RD图是一个**包含目标径向几何结构（距离维）和运动/微动特征（多普勒维）的二维复数散射中心分布图**。推导中忽略的RVP、距离-速度耦合和MTRC，都有明确的数学不等式条件，在工程实现中必须根据具体指标决定是否补偿。

---

## 六、距离-速度耦合项详解

上一节把 $$2\pi \gamma \tau_{ref} \Delta\tau$$ 归到"能忽略则忽略、该补偿就补偿"的一类，但没说清它凭什么把距离和速度绑在一起。这一节单独把它拆开看（注意 $$\gamma$$ 是差频产生的核心系数，不能省）：

### 第一步：展开相对时延，暴露速度变量

前面定义的相对时延是：

$$
\Delta\tau = \tau_i - \tau_{ref} = \frac{2R_\Delta(t_m)}{c}
$$

其中 $$R_\Delta(t_m) = R_{\Delta 0} + v t_m$$（$$R_{\Delta 0}$$ 是初始相对距离，$$v$$ 是速度，$$t_m$$ 是慢时间）。
所以：

$$
\Delta\tau = \frac{2R_{\Delta 0}}{c} + \frac{2v t_m}{c}
$$

### 第二步：代入耦合项，看它变成了什么
将 $$\Delta\tau$$ 代入 $$2\pi \gamma \tau_{ref} \Delta\tau$$ 中：

$$
\Phi_{coup} = 2\pi \gamma \tau_{ref} \left( \frac{2R_{\Delta 0}}{c} + \frac{2v t_m}{c} \right)
$$

$$
\Phi_{coup} = \underbrace{\frac{4\pi \gamma \tau_{ref} R_{\Delta 0}}{c}}_{\text{常数相位}} + \underbrace{\frac{4\pi \gamma \tau_{ref} v}{c} t_m}_{\text{随慢时间线性变化的相位}}
$$

### 第三步：为什么叫“距离-速度耦合”？
看上面第二项 $$\frac{4\pi \gamma \tau_{ref} v}{c} t_m$$。这是一个关于慢时间 $$t_m$$ 的线性相位。在雷达中，**线性相位就是频率**。

对慢时间 $$t_m$$ 做FFT（多普勒维压缩）时，这一项会产生一个附加的多普勒频率：

$$
\Delta f_d = \frac{2\gamma \tau_{ref} v}{c} = \frac{4\gamma R_{ref} v}{c^2}
$$

（注意：$$\tau_{ref} = 2R_{ref}/c$$）

**真相大白：**
这个附加的多普勒频率 $$\Delta f_d$$，**正比于参考距离 $$R_{ref}$$，也正比于目标速度 $$v$$**。
*   这意味着：**多普勒维测出来的“速度”，不仅取决于目标真实的 $$v$$，还取决于所选参考距离 $$R_{ref}$$。**
*   同样，在快时间维，差频频率 $$f_{if} = -\frac{2\gamma}{c} R_\Delta(t_m)$$。因为 $$R_\Delta(t_m)$$ 里含有 $$v t_m$$，所以**距离维的峰值位置会随着慢时间 $$t_m$$ 移动**（这就是距离走动）。

**“距离（$$R_{ref}$$或$$R_{\Delta 0}$$）”和“速度（$$v$$）”通过这个乘积项纠缠在了一起，无法直接独立解耦。** 这就是“距离-速度耦合”（Range-Doppler Coupling, RDC）的物理本质。

### 第四步：耦合带来的后果
1.  **测距误差与散焦**：由于 $$v t_m$$ 的存在，目标在RD图上的亮斑会在距离维倾斜（距离走动），如果不去补偿，直接做慢时间FFT，能量无法聚焦，多普勒维的sinc主瓣会展宽、幅度下降（散焦）。
2.  **测速偏差**：多普勒频率 $$f_d = -\frac{2v}{\lambda} + \Delta f_d$$。由于 $$\Delta f_d$$ 的存在，测出的速度是有偏的。
3.  **参考距离依赖**：改变参考距离 $$R_{ref}$$，测出的多普勒频率也会跟着变，这显然不是真实物理速度。

### 第五步：什么条件下可以忽略这一项？（工程边界）
如果要在推导中省掉这一项，必须满足：

$$
\frac{4\pi \gamma \tau_{ref} v}{c} t_m \ll \pi \quad (\text{即在CPI内相位变化远小于}\pi)
$$

化简得：

$$
\frac{4\gamma R_{ref} v T_{CPI}}{c^2} \ll 1
$$

如果雷达带宽极大（$$\gamma$$ 大）、参考距离很远（$$R_{ref}$$ 大）、目标速度很快（$$v$$ 大）、观测时间很长（$$T_{CPI}$$ 大），这一项就**绝对不能忽略**。

### 工程上如何解耦
在ISAR成像或宽带雷达处理中，通常会先进行**粗测速**（通过其他手段或粗略估计），然后构造一个补偿相位：

$$
\Phi_{comp} = -2\pi \gamma \tau_{ref} \frac{2\hat{v} t_m}{c}
$$

在慢时间域乘上这个补偿因子，把 $$2\pi \gamma \tau_{ref} \Delta\tau$$ 中的速度耦合项“抵消”掉，然后再做慢时间FFT，才能得到聚焦良好的RD图。

### 小结
$$2\pi \gamma \tau_{ref} \Delta\tau$$ 之所以叫耦合项，是因为：
1.  $$\Delta\tau$$ 里面藏着 $$v t_m$$。
2.  它产生了一个附加多普勒频率 $$\frac{4\gamma R_{ref} v}{c^2}$$。
3.  它导致了距离维的走动（MTRC）和多普勒维的偏移，使得“测距”和“测速”互相干扰，必须通过运动补偿（去斜、Keystone变换等）来解耦。
