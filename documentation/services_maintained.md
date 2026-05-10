# 🧩 GitHub Runners Architecture (Kubernetes-based)

Esta infraestructura de GitHub Actions runners está organizada por tipo de workload y orquestada sobre Kubernetes con capacidades de autoscaling y despliegue por runner sets.

---

# ⚙️ 1. Core Runner Sets (Base CI/CD)

## 🔹 runner-set-standard
- Runner Linux de propósito general  
- Incluye: `curl`, `git`, `wget`, `gnupg`, `openssh`, `sonarqube cli`, librerías UI  
- Uso: pipelines CI/CD genéricos  

---

## 🔹 runner-set-cd (Continuous Deployment)
- Runner enfocado a despliegues  
- Incluye:
  - Docker  
  - docker-compose (v2.24)  
  - Kubectl
  - Helm
  - Kustomize
  - Golang for scripting and configuration management
  - github CLI
  - herramientas de build  
- Uso:
  - Infraestructura como código (IaC)  
  - Deployments basados en contenedores  

---

## 🔹 runner-set-dind (Docker-in-Docker)
- Runner with internal docker engine
- docker buildx installed
- dockerd engine installed
- qemu-user-static for multiarch simulation
- both docker and runner container specified from helm chart values
- Permite ejecutar contenedores dentro del runner  
- Tiers disponibles:
  - small / medium / large  
- Uso:
  - builds de imágenes  
  - pipelines complejos con Docker  
  - pruebas de aplicaciones en multiples arquitecturas

---

# 🪟 2. Platform-Specific Runners

## 🔹 runner-set-clarity (Windows / .NET)
- Windows Server Core  
- Incluye:
  - Visual Studio 2022 Build Tools (MSBuild)  
  - .NET Framework 3.5  
  - DigiCert Keylocker (code signing)  
  - GuardIT (obfuscation)  
- Uso:
  - aplicaciones .NET con firma y seguridad  

---

## 🔹 runner-set-tools (Windows Build Tools)
- Runner Windows con toolchain extendido  
- Incluye:
  - .NET 7 SDK  
  - MSBuild, NuGet  
  - Cosign (firma de contenedores)  
  - jq  
  - Visual Studio 2019/2022 components  
- Uso:
  - builds complejos multi-toolchain  

---

# 📱 3. Specialized Development Runners

## 🔹 runner-set-mobile (Android)
- Entorno completo para Android  
- Incluye:
  - Android SDK + Emulator (Android 13)  
  - Build Tools, Bundle Tool  
  - Node.js 20, OpenJDK  
- Uso:
  - builds móviles  
  - testing con emulador  

---

## 🔹 runner-set-ddr (Firmware / Embedded)
- Basado en Android con toolchain embebido  
- Incluye:
  - arm-gcc, ninja-build, ccache  
  - dfu-util, device-tree-compiler  
  - lcov (coverage)  
  - MySQL client  
- Uso:
  - firmware  
  - IoT  
  - embedded systems  

---

## 🔹 runner-set-receiver (Data / Python)
- Runner centrado en Python  
- Basado en Ubuntu 20.04  
- Incluye:
  - Python 3.x + tooling completo  
  - dependencias de testing (build, compliance, docs)  
  - librerías embebidas  
- Uso:
  - data processing  
  - machine learning workflows  
  - testing intensivo  

---

# 📡 4. Data Transmission Runners

## 🔹 runner-set-transmitter
- Ubuntu 22.04  
- Incluye:
  - Coverity Scan (análisis estático)  
  - SBOM tooling  
  - configuración SSH  
- Uso:
  - reporting  
  - análisis de código  
  - transmisión segura  

---

## 🔹 runner-set-transmitter-lite
- Versión ligera  
- Sin Coverity completo  
- Uso:
  - pipelines más rápidos  
  - menor consumo de recursos  

---

# 🏗️ 5. Infrastructure & Orchestration

## 🔹 macstadium
- Runners macOS en infraestructura externa  
- Basado en VMs macOS  
- Incluye:
  - manifests de Kubernetes  
- Uso:
  - builds iOS/macOS  

---

## 🔹 orka-arc (Proof of Concept)
- Orquestación con Orka (macOS sobre Kubernetes)  
- Autoscaling rápido (~30–60s)  
- Separación por “runner flavors”  
- Uso:
  - escalamiento dinámico de runners macOS  

---

## 🔹 cluster-secret-store
- Gestión de secretos en Kubernetes  
- Maneja:
  - secretos para entornos dev/prod  
- Uso:
  - credenciales seguras para runners  

---

# 🔧 6. Operations & Service Maintenance

## 🔹 Code Quality Platform (SonarQube)
- Mantenimiento y operación de SonarQube 
- Integración de SonarScanner CLI en pipelines de CI/CD (tambien instalandolo en algunos github runners para scaneo de seguridad)
- Uso:
  - análisis estático de código  
  - enforcement de calidad  
  - security scanning  

---

## 🔹 Database Layer (Cloud SQL)
- Base de datos gestionada en Google Cloud SQL  
- Soporte para servicios como:
  - SonarQube  
- Responsabilidades:
  - configuración de instancias  
  - mantenimiento y disponibilidad  
  - gestión de conexiones seguras  

---

## 🔹 Observability Integration (Datadog)
- Instalación e integración de agentes de Datadog en pods de Kubernetes  mediante daemonsets definiendo que cada nodo debia tener un agente de datadog instalado
- Instalacion de datadog agent en cluster de kubernetes para monitoreo
- Recolección de:
  - métricas  
  - logs  
  - eventos de infraestructura  
- Integración con:
  - pipelines CI/CD  
  - servicios desplegados en el cluster  
- Uso:
  - monitoreo de performance de runners e informacion como:
    - average runners per hour (concurrency)
    - cpu, memory and storage usage
    - runners demand
    - average time of queues
    - etc.
  - visibilidad del estado del sistema  

---


## 🔹 General Maintenance Activities
- Actualización de versiones (tools, runners, plugins)
- Troubleshooting de pipelines y runners
- Optimización de recursos (costos y performance)
- Hardening de seguridad en servicios e infraestructura

---