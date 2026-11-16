# VyrnOutputLicense (Vyrn Licensing & Output Ownership Policy)  

Copyright (c) 2016-2026 Ji-Feng Tsai  

This document clarifies the licensing terms for the **Vyrn** toolchain, its runtime components, and applications or compiled artifacts created using Vyrn.

---

## 1. Vyrn Toolchain & Runtime (MIT License)  

The Vyrn compiler, virtual machine (VM), standard library, official IDE, and runtime components—including `Vyrn.dll`, `libvyrnrt`, and launcher stubs—are licensed under the **MIT License**. 

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Vyrn software, subject to the conditions of the `LICENSE` file in the root of this repository.

---

## 2. Ownership of User Code & Compiled Outputs  

* **Your Code is Yours:** Any source code written in the Vyrn programming language, along with its compiled or bundled outputs (including `.vyrnc` bytecode, generated C source files, and standalone or native executables produced via `vyrn standalone` or `vyrn compile`), remains the sole intellectual property of its respective author(s).
* **No Copyleft / Viral Restrictions:** Using Vyrn to write, compile, or package software does **not** place your code or its outputs under the MIT License or any other open-source license unless you choose to do so.

---

## 3. Royalty-Free Commercial & Proprietary Distribution  

* **Freedom to License:** You may distribute, license, or sell applications built with Vyrn under any license of your choice, including proprietary and closed-source commercial licenses, with zero royalty fees.
* **Bundled Runtime Attribution:** When distributing applications that bundle Vyrn runtime components (such as `Vyrn.dll`, launcher stubs, or statically linked `libvyrnrt`), you only need to comply with the standard MIT License attribution requirement—specifically, including the original Vyrn copyright notice and MIT permission notice in your application's documentation, `THIRD-PARTY-LICENSES` file, or about screen.
