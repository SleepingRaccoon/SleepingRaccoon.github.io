---
title: CUDA入门
order: 1
description: 搜集网上各类散列教程，汇编成册
---

## 1 先从基本概念入手

- [开篇：为什么学CUDA？](https://zhuanlan.zhihu.com/p/2010396082744624644)
- [CUDA编程模型：Grid、Block、Thread的前世今生](https://zhuanlan.zhihu.com/p/2010714643467871066)
- [GPU内存体系：从全局内存到寄存器](https://zhuanlan.zhihu.com/p/2010715524221408095)
- [GPUKernel第一课：Roofline](https://zhuanlan.zhihu.com/p/2074137890158913526)
- [深入SIMT执行模型：Warp、分支与占用率](https://zhuanlan.zhihu.com/p/2012210771661181752)

## 2 学会几个简单的基本内核


## 3 学会使用 NVIDIA Nsight 工具

- [CUDA性能分析实战：Nsight Systems和Nsight Compute入门](https://zhuanlan.zhihu.com/p/2025619489903900661)


## 4 CUTLASS




## 一、并行划分

### 1.1 线程与块的映射

#### 1.1.1 一维映射

（占位正文。）

#### 1.1.2 二维映射

（占位正文。）

### 1.2 边界处理

（占位正文。）

## 二、渲染检查：公式、代码、表格

行内公式写成 `$$N$$`，独立公式前后留空行：

$$
T_{\text{total}} \approx \frac{N}{B \cdot T}
$$

代码块：

```cuda
__global__ void placeholderKernel(float *x, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        x[i] *= 2.0f;
    }
}
```

| 项目 | 说明 |
| :--- | :--- |
| 占位 | 待替换 |
| 目录 | 由 `##`、`###`、`####` 自动生成 |

## 三、小结

（占位正文。）
