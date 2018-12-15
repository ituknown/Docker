# Docker 概念

Docker 是一个供开发人员和系统管理员使用容器开发、部署和运行应用程序的平台。使用 `Linux` 容器部署应用程序称为容器化。容器不是新的，但是它们用于轻松部署应用程序却是新的。

将容器进行打包又称为集装箱化，容器化技术越来越受欢迎，因为:

- **灵活:** 即使是最复杂的应用程序也可以被容器化。
- **轻量级:** 容器利用并共享主机内核。
- **可互换:** 可以动态部署更新和升级。
- **可移植性:** 可以在本地构建，部署到云，并在任何地方运行。
- **可伸缩:** 可以增加和自动分发容器副本。
- **可堆叠:** 可以垂直地、动态地堆叠服务。

![laurel-docker-containers](./images/orientation/laurel-docker-containers.png)

# 镜像与容器

<!--sec data-title="镜像" data-id="section0" data-show=true ces-->
容器（`container`）是通过运行镜像（`image`）启动或者说生成的。镜像（`image`）是一个可执行包，它包含运行应用程序所需的所有东西 -- 代码、运行时需要的类库、环境变量和配置文件等。
<!--endsec-->

<!--sec data-title="容器" data-id="section1" data-show=true ces-->
容器（`container`）是镜像（`image`）的运行时实例 -- 镜像在执行时在内存中变成什么(即具有状态的映像或用户进程)。在文件系统中（`centos`、`MacOS`）可以通过执行 `docker ps` 命令查看正在运行的容器。
<!--endsec-->

# Docker 与 VM

一个容器在 `Linux` 本地（*natively*）上运行，并与其他容器共享主机的内核。它运行一个离散的进程，暂用的内存不必任何其他可执行文件多，这使得它是一个轻量级的。

相反，虚拟机（`VM`）是运行一个成熟的 *来宾（guest）* 操作系统，通过 `Hypervisor` 虚拟的访问资源。

<table>
  <tbody>
    <tr>
      <td><img src="./images/orientation/Container.png" alt="Container stack example"></td>
      <td><img src="./images/orientation/VM.png" alt="Virtual machine stack example"></td>
    </tr>
  </tbody>
</table>

从上图可知 Docker 没有传统虚拟化中的 `Hypervisor` 层。因此，docker 是基于容器技术的轻量级虚拟化，相对于传统虚拟化技术省去了 `Hypervisor` 层的开销，而且其虚拟化技术是基于内核的 Cgroup 和 Namespace 技术，处理逻辑与内湖深度融合，所以在很多方面，它的性能与物理机非常接近，这是虚拟机远远不能够比拟的。

在通信上，docker 并不会直接与内核交互，他是通过一个更底层的工具 Libcontaoner 与内核交互的。

虚拟机是用来进行硬件资源划分的完美解决方案，它利用了硬件虚拟化技术来实现对资源的彻底分离；而容器则是操作系统级别的虚拟化，利用的是内核 Cgroup 和 Namespace 特性，此功能完全通过软件来实现，仅仅是进程本身就可以与其他进程隔离，不需要任何辅助。

Docker 容器与主机共享操作系统内核，不同的容器之间可以共享部分系统资源。因此，容器更轻量级，消耗的资源也更少。

而虚拟机会独占分配给自己的资源，几乎不存在资源共享。各虚拟机实例之间近乎完全隔离，所以虚拟机更加重量级，也会消耗更多的资源。

我们可以很轻松的在一台普通的 Linux 机器上运行 100 或更多的 Docker 容器，而且不会占用太多系统资源；而在单台几区上不可能创建 100 台虚拟机。

另外，docker 容器启动很快，通常是秒级甚至是毫秒级启动。而虚拟机的启动虽然快于物理机器，但是启动时间也是在数秒至数十秒的量级。

下面看下 VM 与 Docker 对比：

|   特性      |   容器      |   虚拟机     |
| :--------: | :--------: | :----------: |
| 启动       | 秒级       | 分钟级       |
| 硬盘使用   | 一般为 `MB`| 一般为 `GB`  |
| 性能       | 接近原生   | 弱于         |
| 系统支持量 | 单机支持上千个容器 | 一般几十个 |


# 为什么要使用 Docker？

现在再来总结下为什么要使用 Docker。作为一种新兴的虚拟化方式，Docker 跟传统的虚拟化方式相比具有众多的优势。

<!--sec data-title="更高效的利用系统资源" data-id="section3" data-show=true ces-->
由于容器不需要进行硬件虚拟以及运行完整操作系统等额外开销，Docker 对系统资源的利用率更高。无论是应用执行速度、内存损耗或者文件存储速度，都要比传统虚拟机技术更高效。因此，相比虚拟机技术，一个相同配置的主机，往往可以运行更多数量的应用。
<!--endsec-->

<!--sec data-title="更快速的启动时间" data-id="section4" data-show=true ces-->
传统的虚拟机技术启动应用服务往往需要数分钟，而 Docker 容器应用，由于直接运行于宿主内核，无需启动完整的操作系统，因此可以做到秒级、甚至毫秒级的启动时间。大大的节约了开发、测试、部署的时间。
<!--endsec-->

<!--sec data-title="一致的运行环境" data-id="section5" data-show=true ces-->
开发过程中一个常见的问题是环境一致性问题。由于开发环境、测试环境、生产环境不一致，导致有些 bug 并未在开发过程中被发现。而 Docker 的镜像提供了除内核外完整的运行时环境，确保了应用运行环境一致性，从而不会再出现 *「这段代码在我机器上没问题啊」* 这类问题。
<!--endsec-->

<!--sec data-title="持续交付和部署" data-id="section6" data-show=true ces-->
对开发和运维（[DevOps](https://zh.wikipedia.org/wiki/DevOps)）人员来说，最希望的就是一次创建或配置，可以在任意地方正常运行。

使用 Docker 可以通过定制应用镜像来实现持续集成、持续交付、部署。开发人员可以通过 [Dockerfile](../image/dockerfile/) 来进行镜像构建，并结合 [持续集成(Continuous Integration)](https://en.wikipedia.org/wiki/Continuous_integration) 系统进行集成测试，而运维人员则可以直接在生产环境中快速部署该镜像，甚至结合 [持续部署(Continuous Delivery/Deployment)](https://en.wikipedia.org/wiki/Continuous_delivery) 系统进行自动部署。

而且使用 `Dockerfile` 使镜像构建透明化，不仅仅开发团队可以理解应用运行环境，也方便运维团队理解应用运行所需条件，帮助更好的生产环境中部署该镜像。
<!--endsec-->

<!--sec data-title="更轻松的迁移" data-id="section7" data-show=true ces-->
由于 Docker 确保了执行环境的一致性，使得应用的迁移更加容易。Docker 可以在很多平台上运行，无论是物理机、虚拟机、公有云、私有云，甚至是笔记本，其运行结果是一致的。因此用户可以很轻易的将在一个平台上运行的应用，迁移到另一个平台上，而不用担心运行环境的变化导致应用无法正常运行的情况。
<!--endsec-->

<!--sec data-title="更轻松的维护和扩展" data-id="section8" data-show=true ces-->
Docker 使用的分层存储以及镜像的技术，使得应用重复部分的复用更为容易，也使得应用的维护更新更加简单，基于基础镜像进一步扩展镜像也变得非常简单。此外，Docker 团队同各个开源项目团队一起维护了一大批高质量的 [官方镜像](https://store.docker.com/search?q=&source=verified&type=image)，既可以直接在生产环境使用，又可以作为基础进一步定制，大大的降低了应用服务的镜像制作成本。
<!--endsec-->
