*This project has been created as part of the 42 curriculum by smarquez, nmagro-r, pablalva.*

# Inception-of-Things

## Description

Inception-of-Things (IoT) is a short introduction to Kubernetes. We build small clusters with
**K3s** and **K3d**, create the virtual machines with **Vagrant**, and finish with a GitOps workflow
driven by **Argo CD**.

| Part | What it does | Main tools |
|---|---|---|
| **P1** | Two virtual machines: `smarquezS` runs K3s as a server (controller) and `smarquezSW` as an agent. | Vagrant, VirtualBox, K3s |
| **P2** | One virtual machine (`smarquezS`) with K3s and three web apps. The `Host` header decides which app answers; `app2` has 3 replicas. | Vagrant, K3s, Traefik Ingress |
| **P3** | A K3d cluster with Argo CD. Argo CD deploys the app from a public GitHub repo into the `dev` namespace and follows its version (`v1` ↔ `v2`). | Docker, K3d, Argo CD |
| **Bonus** | Same as P3, but the repo lives in a GitLab instance running inside the cluster. | GitLab, K3d, Argo CD |

### Team

| Member | 42 login | Parts |
|---|---|---|
| Sergio | `smarquez` | P1, P2 |
| Nacho | `nmagro-r` | P2, P3 |
| Pablo | `pablalva` | P3, Bonus |

### Repository structure

```
.
├── p1/      Vagrantfile, scripts/ (ip.sh, server.sh, worker.sh), confs/
├── p2/      Vagrantfile, scripts/ (ip.sh, server.sh), confs/ (3 apps, nginx config, Ingress)
├── p3/      Makefile, scripts/ (setup, cluster, namespace, Argo CD...), confs/ (k3d config, Argo CD Application)
└── bonus/   Makefile, scripts/ (same as p3 + GitLab), confs/ (k3d config, GitLab, Application, app/)
```

The app that Argo CD deploys in P3 lives in a separate public GitHub repo, with the login of a
group member in its name, as the subject requires:
[`nmagro-r/nmagro-r-iot-argocd`](https://github.com/nmagro-r/nmagro-r-iot-argocd) (folder `k8s/`).

## Instructions

### Where each part runs

- **P1 and P2** create virtual machines with Vagrant. The host needs VirtualBox, Vagrant and hardware
  virtualization **with nested paging** (`grep -wE 'npt|ept' /proc/cpuinfo`). On the 42 workstations
  we run them directly on the workstation: inside our Ubuntu VM the nested machines cannot run
  (see [Problems we ran into](#problems-we-ran-into)).
- **P3 and the bonus** only use Docker containers (K3d), so they run inside an **Ubuntu 24.04** VM.
  `setup.sh` installs Docker, k3d and kubectl (it asks for `sudo`).

On the 42 workstations the home folder is small, so Vagrant must keep its boxes on the big disk:

```bash
echo 'export VAGRANT_HOME=$HOME/goinfre/vagrant.d' >> ~/.zshrc
export VAGRANT_HOME=$HOME/goinfre/vagrant.d
```

### Part 1: K3s and Vagrant

```bash
cd p1 && vagrant up
vagrant ssh smarquezS -c "kubectl get nodes -o wide"
vagrant ssh smarquezS -c "ip -4 a | grep 192.168.56"
vagrant ssh smarquezSW -c "ip -4 a | grep 192.168.56"
vagrant destroy -f    # when finished (P2 uses the same IP)
```

Expected: both nodes `Ready`, `smarquezS` on `192.168.56.110` and `smarquezSW` on `192.168.56.111`,
`vagrant ssh` without a password and `kubectl` without `sudo`.

How it works:

- **Box:** Fedora 45, downloaded from Fedora's own server (`config.vm.box_url`), as the subject requires.
- **Resources:** `smarquezS` has 2 GB of RAM and 1 CPU; `smarquezSW` has 1 GB and 1 CPU.
- **Network:** `scripts/ip.sh` sets the private IP with NetworkManager (`nmcli`). The interface is
  called `enp0s8` instead of `eth1`, which the subject accepts on modern distributions.
- **K3s:** `scripts/server.sh` installs K3s in server mode bound to `.110`, and
  `scripts/worker.sh` installs the agent and joins it to `https://192.168.56.110:6443`.
  Flannel uses the private interface instead of the NAT one.
- **Token:** the Vagrantfile generates the K3s token in `p1/.k3s-token` (ignored by Git), so no
  secret is stored in the repo.

### Part 2: K3s and three simple applications

```bash
cd p2 && vagrant up
vagrant ssh smarquezS -c "kubectl get all; kubectl get ingress"
for h in app1.com app2.com app2.com otro.com; do
  echo "--- $h"; curl -s -H "Host: $h" 192.168.56.110 | grep -E "Hello|pod:"
done
curl -s 192.168.56.110 | grep -E "Hello|pod:"     # no Host header -> app3
vagrant destroy -f
```

Expected: `app-two` with 3/3 replicas, `app1.com` → app1, `app2.com` → app2 (a different pod each
time) and any other host → app3.

- **Apps:** three nginx Deployments (`confs/app1.yaml`, `app2.yaml`, `app3.yaml`), each with its own page.
- **Pod name:** nginx Server Side Includes (`confs/nginx-ssi.yaml`) print which pod answered, to show
  that the 3 replicas of app2 share the load.
- **Ingress:** `confs/ingress.yaml` uses Traefik, which comes with K3s. The rule without a host sends
  everything else to app3.
- **Provisioning:** `scripts/server.sh` installs K3s, applies `confs/` and waits until the three apps
  are ready.

### Part 3: K3d and Argo CD

```bash
cd p3 && make init      # installs everything, then keeps the Argo CD UI open on purpose
```

`make init` runs, in order: `setup.sh`, `cluster.sh` (K3d cluster `iot-cluster`, 1 server and 1 agent),
`namespace.sh` (`argocd` and `dev`), `initArgo.sh`, `gitops.sh` (applies `confs/argocd-app.yaml`) and
`argoUI.sh`. The Argo CD UI is at `https://localhost:8443` (user `admin`; the password is printed).

In another terminal:

```bash
kubectl get ns
kubectl get pods -n dev
kubectl -n argocd get application wil-playground
curl http://localhost:8888/          # {"status":"ok", "message": "v1"}
```

Demo: in GitHub, edit `k8s/deployment.yaml` in `nmagro-r/nmagro-r-iot-argocd` and change
`wil42/playground:v1` to `:v2`. Argo CD checks the repo every 3 minutes; to sync right away:

```bash
kubectl -n argocd annotate application wil-playground argocd.argoproj.io/refresh=normal --overwrite
kubectl -n dev rollout status deployment/wil-playground
curl http://localhost:8888/          # now "v2"
```

Clean up with `Ctrl+C` and `make fclean`. Other targets: `make re` (fclean + init) and
`make purge` (also uninstalls Docker, k3d and kubectl).

### Bonus: GitLab

```bash
cd bonus && make init
```

Same flow as P3, plus `gitlab.sh` and `gitlabRepo.sh`. The order is: `setup.sh`, `cluster.sh`,
`namespace.sh` (`argocd`, `dev`, `gitlab`), `gitlab.sh`, `initArgo.sh`, `gitlabRepo.sh`, `gitops.sh`
and `argoUI.sh`.

- **GitLab:** the official `gitlab/gitlab-ce` image (`confs/gitlab.yaml`), at `http://localhost`
  (user `root`; the password is printed). The first start takes several minutes.
- **Repo:** `gitlabRepo.sh` creates the public project `root/nmagro-r-iot-argocd` and uploads
  `confs/app/` into `k8s/`, using `gitlab-rails runner` inside the pod, so no token is needed.
- **Argo CD:** reads that project through the cluster's internal address,
  `http://gitlab.gitlab.svc.cluster.local/root/nmagro-r-iot-argocd.git`.

In another terminal:

```bash
cd bonus
kubectl get pods -n gitlab
kubectl -n argocd get application wil-playground
curl http://localhost:8888/          # v1
bash scripts/version.sh v2           # commits v2 in GitLab and refreshes Argo CD
kubectl -n dev rollout status deployment/wil-playground
curl http://localhost:8888/          # v2
bash scripts/version.sh v1
```

Clean up with `Ctrl+C` and `make fclean`.

## Problems we ran into

Most of our time went into the environment, not into the Kubernetes files. This is what failed, why,
and what we changed.

### Virtual machines (P1 and P2)

| Problem | Cause | Fix |
|---|---|---|
| The HashiCorp public box registry is not guaranteed after 2026, and Ubuntu only publishes a Vagrant box for 22.04 | Subject rule and Ubuntu's release policy | `config.vm.box_url` pointing to a box published by the distribution itself (first Rocky Linux 10, then Fedora 45) |
| On a Windows laptop the VMs were extremely slow and the agent never joined | Hyper-V stayed active (Windows security features based on it), even with `hypervisorlaunchtype off` | We stopped using that laptop |
| Ubuntu's `virtualbox` package failed to install inside our Ubuntu VM | VirtualBox 7.0.16 does not build for the VM's kernel 7.0 | Oracle's `virtualbox-7.2` package |
| Rocky Linux 10 crashed at boot (`Kernel panic ... exitcode=0x00007f00`) | Rocky 10 requires x86-64-v3 CPU instructions (AVX, AVX2...). Nested VMs did not receive them, and the VirtualBox 7.0.18 on the 42 workstations has a bug with these systems (fixed in 7.2.10) | **Fedora 45**: latest stable release, official VirtualBox box, no x86-64-v3 requirement |
| Inside our Ubuntu VM, K3s never answered (`TLS handshake timeout`) | The 42 workstations do not give nested paging (`npt`) to the VM, so a VM inside it spends almost all its CPU on memory translation | P1 and P2 run on the workstation itself |
| `No space left on device` when adding the box | The home folder on the workstations is only a few GB | `VAGRANT_HOME` in `~/goinfre` |
| K3s failed with `listen tcp 192.168.56.110:6443: bind: cannot assign requested address` | Vagrant 2.4.1 (the workstations' version) does not set the static IP on Fedora 45; VirtualBox's DHCP gave the card `.101` instead | `auto_config: false` and our own `scripts/ip.sh` (`nmcli`), which works with any Vagrant version |
| The agent stayed forever in `Starting k3s-agent` | With 1 GB, `smarquezS` was using swap and answered too slowly | 2 GB for `smarquezS`, which is what K3s asks for a server. The subject only *advises* the minimum |
| `kubectl` needed `sudo`; K3s token written in the repo | Default K3s permissions; first version of the Vagrantfile | `--write-kubeconfig-mode=644`; token generated in `.k3s-token`, ignored by Git |

### K3d, Argo CD and GitLab (P3 and bonus)

| Problem | Cause | Fix |
|---|---|---|
| Installing the official Argo CD manifest failed | Some Argo CD CRDs are too big for a normal (client-side) `kubectl apply` | `kubectl apply --server-side --force-conflicts` |
| The Argo CD UI could not use port 8080 | The K3d load balancer already publishes 8080 | `port-forward` on `8443` |
| A version change took up to 3 minutes to appear | Argo CD polls the repo every 3 minutes | `version.sh` (and the demo) add the `refresh` annotation |
| `helm install gitlab/gitlab` refused to install | Since chart 10.0 (GitLab 19) the chart no longer bundles PostgreSQL, Redis or storage | We dropped Helm and use the official all-in-one image `gitlab/gitlab-ce` with a Deployment, a Service and a volume |
| GitLab took too long and the script gave up | The first start configures everything and takes several minutes | Longer wait in `gitlab.sh` and a readiness probe on `/-/readiness` |
| Argo CD needed credentials to read GitLab | A private repo needs a token | Public project, created with `gitlab-rails runner`, read through the internal service URL |
| `curl` returned `000` and K3d could not publish port 80 | A K3s service installed earlier on the same machine was using port 80 | Stop it with `sudo systemctl disable --now k3s` |
| `kubectl` talked to the wrong cluster | Next to K3s, `kubectl` reads `/etc/rancher/k3s/k3s.yaml` by default | `export KUBECONFIG=$HOME/.kube/config` |

## Resources

- [Vagrant documentation](https://developer.hashicorp.com/vagrant/docs): boxes, `box_url`, private networks, shell provisioner
- [VirtualBox manual](https://www.virtualbox.org/manual/) and [VirtualBox 7.2 changelog](https://www.virtualbox.org/wiki/Changelog-7.2)
- [Fedora Cloud images](https://fedoraproject.org/cloud/download) and [Rocky Linux 10 release notes](https://rockylinux.org/news/rocky-linux-10-0-ga-release)
- [K3s documentation](https://docs.k3s.io/): installation options, requirements and resource profiling
- [k3d documentation](https://k3d.io/)
- [Kubernetes documentation](https://kubernetes.io/docs/home/): Deployments, Services, Ingress
- [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/): getting started, Application spec, automated sync
- [GitLab Docker installation](https://docs.gitlab.com/install/docker/) and [Rails Runner](https://docs.gitlab.com/administration/operations/rails_console/)
- [wil42/playground on Docker Hub](https://hub.docker.com/r/wil42/playground)

### AI usage

We used an AI assistant (Claude, by Anthropic) for:

- **Documentation:** this README and the step-by-step guides we used to test each part.
- **Git:** writing commit messages and pull requests, and merging branches into `development`.
- **Version problems:** diagnosing the compatibility problems listed above (Rocky Linux 10 and
  x86-64-v3, the VirtualBox and Vagrant versions on the 42 workstations, nested virtualization, the
  GitLab Helm chart) and proposing the changes that fixed them.

We reviewed what the assistant proposed before applying it, and we tested each part on real
machines: P1 and P2 on a 42 workstation, P3 and the bonus on our own laptops.
