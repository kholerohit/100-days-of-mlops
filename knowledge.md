# MLOps Practical Knowledge Guide

A hands-on reference for the concepts and operating habits used throughout this 100-day project. Use it beside each day's `task.md`; the task defines the required end state, this guide gives you the mental models and tools to get there, and `solution.md` remains the reference walkthrough.

## Contents

- [How to Work Through a Lab](#how-to-work-through-a-lab)
- [1. Python Environments and Project Quality](#1-python-environments-and-project-quality)
- [2. Data and Pipeline Versioning with DVC](#2-data-and-pipeline-versioning-with-dvc)
- [3. Experiment Tracking and Model Lifecycle](#3-experiment-tracking-and-model-lifecycle)
- [4. Reliable Training and Evaluation](#4-reliable-training-and-evaluation)
- [5. Feature Stores, Data Quality, and Secrets](#5-feature-stores-data-quality-and-secrets)
- [6. Containers and Reproducible Builds](#6-containers-and-reproducible-builds)
- [7. Model APIs and Deployment Patterns](#7-model-apis-and-deployment-patterns)
- [8. Metrics, Dashboards, and Alerts](#8-metrics-dashboards-and-alerts)
- [9. CI, Releases, and GitOps](#9-ci-releases-and-gitops)
- [10. Workflow Orchestration and Kubernetes](#10-workflow-orchestration-and-kubernetes)
- [End-to-End MLOps System](#end-to-end-mlops-system)
- [Troubleshooting Checklist](#troubleshooting-checklist)
- [Day Map](#day-map)
- [Useful References](#useful-references)

## How to Work Through a Lab

Treat each task as an operational change with a verifiable outcome, not as a command-typing exercise.

1. **Read the end state first.** Extract the required files, services, versions, endpoints, and expected status. Note the host, namespace, working directory, and any lab-specific ports.
2. **Take a baseline.** Inspect the existing files and service state before changing anything. Use `git status`, `ls`, `cat`, `docker ps`, `kubectl get`, health endpoints, and logs as appropriate.
3. **Trace the contract.** Follow the value or artifact across boundaries: config to process, training output to registry, service port to container port, or metric endpoint to dashboard query.
4. **Change the smallest relevant surface.** Preserve existing conventions and avoid changing unrelated files, credentials, or infrastructure.
5. **Validate in layers.** Check syntax/configuration, run the focused command, inspect the resulting state, then test the user-visible or end-to-end behavior.
6. **Check failure handling and cleanup.** A passing happy path is not enough if errors are swallowed, secrets are printed, or a background process is left in an unsafe state.

The solution files use the lab's own environment, which may have preinstalled services and special browser ports. Prefer the paths and versions written in the task over assumptions from a different machine.

## 1. Python Environments and Project Quality

### Keep dependencies reproducible

An environment isolates project packages from the operating system. Always check that `python` and `pip` point to the same environment before installing or testing.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install numpy pandas scikit-learn matplotlib
python -m pip freeze > requirements.txt
python -c 'import numpy, pandas, sklearn, matplotlib; print("imports OK")'
```

Use `python -m pip` to bind pip to the active interpreter. A `requirements.txt` records a snapshot; for newer projects, a declarative file such as `pyproject.toml` plus a generated lockfile is often a better source of truth. With uv, keep the project specification and lockfile consistent, then use a frozen sync in CI to detect drift.

### Source control and project hygiene

- `.gitignore` stops new untracked files from being added, but does not untrack files already in Git. `git rm --cached path` removes a file from the index while keeping the local copy.
- A Makefile makes common commands discoverable. Recipe lines require tabs; dependencies should express the order between targets. Mark command-only targets `.PHONY`.
- Keep package imports, tests, and build configuration consistent. Test from an installed/editable package context when possible, not only from the repository root where Python may import local files accidentally.
- Formatters, linters, and pre-commit hooks are separate checks. Run them on the same paths and versions used in CI; hook IDs must exist in the declared hook repository revision.
- Cookiecutter templates substitute variables in both filenames and file contents. Render a sample project and search for unresolved `{{ ... }}` expressions.

Useful checks:

```bash
git status --short
python -m pytest -q
ruff check .
black --check .
pre-commit run --all-files
```

## 2. Data and Pipeline Versioning with DVC

DVC complements Git: Git versions code and small metadata; DVC tracks large data/model objects and pipeline outputs. A `.dvc` file or `dvc.lock` stores metadata and hashes, while the DVC cache or remote stores the actual content.

### Track data and configure remotes

```bash
dvc init
dvc add data/raw/train.csv
git add data/raw/train.csv.dvc .gitignore .dvc/config
git commit -m "Track training data with DVC"
dvc remote list
dvc status
```

For object storage such as an S3-compatible service, distinguish the remote name, bucket/path, endpoint URL, and credentials. Configure secrets outside committed files. Test connectivity and permissions before pushing; the endpoint used by a container may differ from the host-facing URL.

```bash
dvc push
dvc pull
```

After switching Git branches, use the DVC metadata from that branch and restore the corresponding cached data as needed. A branch checkout alone does not necessarily materialize the right large files.

### Build a reproducible pipeline

A DVC stage declares a command, dependencies, and outputs. A later stage depends on an earlier output, forming a directed acyclic graph (DAG). DVC can then skip work when inputs have not changed.

```yaml
stages:
  prepare:
    cmd: python src/prepare.py
    deps:
      - src/prepare.py
      - data/raw/train.csv
    outs:
      - data/processed/train.csv
  train:
    cmd: python src/train.py
    deps:
      - src/train.py
      - data/processed/train.csv
    params:
      - train.learning_rate
    outs:
      - models/model.pkl
    metrics:
      - reports/metrics.json
```

Common commands:

```bash
dvc repro                 # run changed stages in dependency order
dvc status                # inspect data and pipeline changes
dvc metrics show          # show tracked metrics
dvc exp run               # run an experiment
dvc exp show              # compare experiment results
```

For every stage, compare what the script actually reads/writes with the declared `deps`, `outs`, `params`, and `metrics`. Incorrect paths are a frequent cause of stale outputs and unexpected reruns.

## 3. Experiment Tracking and Model Lifecycle

MLflow separates **tracking metadata** (runs, parameters, metrics, tags) from **artifacts** (models, plots, datasets). A tracking server may use a database backend and a separate artifact store. Client URI, server backend, and artifact destination are different configuration points.

### Log useful runs

Set the tracking URI and experiment before opening a run. Log the values required to reproduce and compare a run, not just a final score.

```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("fraud-detection")

with mlflow.start_run():
    mlflow.log_param("model", "random-forest")
    mlflow.log_param("seed", 42)
    mlflow.log_metric("f1", 0.91)
    mlflow.log_artifact("reports/confusion_matrix.png")
```

Autologging should be enabled before the framework's training call. Confirm that the chosen framework/version is supported and check the run for expected parameters, metrics, and model artifacts.

### Server and artifact troubleshooting

- Confirm the server process is listening and its health/UI endpoint responds.
- Check the server's backend database path and artifact root separately.
- For remote artifact storage, the server and client need compatible URIs and reachable endpoints. Credentials must be available to the process doing the upload/download.
- Browser proxy access can have host/CORS allow-list requirements even when a local `curl` succeeds. Diagnose browser and server connectivity separately.
- Compare runs only when they use compatible datasets, splits, metric definitions, and input schemas. Use MLflow filter syntax for server-side search.

### Registry and serving identity

Register a model from a specific run/artifact URI. A model version is immutable; an alias such as `production` is a movable name that consumers can resolve at startup. Verify that serving references the intended model name and version/alias, and that artifact storage is reachable from the serving process.

## 4. Reliable Training and Evaluation

### Configuration and reproducibility

Make configuration explicit: record the config file, parse it once, validate required keys and types, and log the effective values. Avoid hidden defaults that make two runs look identical while using different settings.

Set random seeds in every library that uses randomness (Python, NumPy, ML framework, and data split). Determinism can also depend on accelerator/backend settings and library versions. Re-run a small experiment and compare the split, parameters, and results.

### Evaluate correctly

- Use the same feature transformations and column order at training and inference.
- Keep labels and predictions aligned; check row counts, class ordering, and missing values.
- Use stratified splits/cross-validation for imbalanced classification when appropriate.
- Report fold-level scores plus a clearly defined aggregate. Do not silently average incompatible metrics.
- Tune on training/validation data, then reserve a holdout set for the final estimate. Avoid leaking future or target information into features.
- Compare candidate models on the same folds and metric contract.

For hyperparameter optimization, define whether the objective is minimized or maximized, return one scalar per trial, and log the parameters and score together. Keep expensive parallelism bounded; worker processes may need importable functions and a guarded entry point.

### Checkpoints and multi-stage scripts

A checkpoint should preserve enough state for the intended resume behavior (typically model state and, when resuming optimization, optimizer state and step/epoch). Load it with an explicit device mapping. In a pipeline, document each stage's input/output contract and test stages independently before running the full chain.

## 5. Feature Stores, Data Quality, and Secrets

### Feast feature stores

A Feast feature repository describes entities, data sources, feature views, and store configuration. `feast apply` registers definitions. The **offline store** supports historical, point-in-time-correct training retrieval; the **online store** serves current feature values at inference.

When a training-set join looks wrong, verify:

- Entity keys and event timestamps exist in the entity dataframe.
- Feature references use the exact `feature_view:feature` names.
- Source field names/types agree with the feature schema.
- Historical retrieval is bounded by each row's event time, preventing future leakage.
- Materialization covers the time range needed for online reads.

### Data quality with Great Expectations

An expectation suite encodes assumptions such as required columns, type, range, uniqueness, and nullability. A checkpoint binds the suite to a datasource/batch and produces a validation result. Inspect the failed expectation and observed value before deciding whether the rule or the input is wrong.

In CI, a failing validation must produce a non-zero process exit code and the workflow must propagate it. Verify the exact data path, suite name, and dependency version used by the job.

### Secrets with HashiCorp Vault

Use a secret manager rather than committed config or workflow text. Vault access depends on the enabled secrets engine version, mount path, policy path, and authentication method. AppRole uses a role ID and secret ID; grant only the needed capabilities and test with the same identity the application uses. Never print secret values or include them in logs/artifacts.

## 6. Containers and Reproducible Builds

A Docker image packages the runtime, dependencies, code, and default process. Keep build context small and install every runtime import, including libraries used only when saving/loading a model.

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

Use a base image compatible with binary dependencies. Alpine uses musl rather than glibc, which can make scientific Python packages fall back to source builds or fail to install. Multi-stage builds can keep compilers and build tooling out of the final image.

```bash
docker build -t fraud-api:dev .
docker run --rm -p 8085:8085 fraud-api:dev
docker run --rm fraud-api:dev python -c 'import sklearn, pandas, numpy'
docker logs <container>
```

Remember:

- `EXPOSE` documents a container port; `-p host:container` publishes it.
- The application must bind to `0.0.0.0` inside the container.
- A Docker health check must use an executable and endpoint available in the image.
- Compose services reach each other by service DNS name and container port, not by `localhost` or the published host port.
- A container being `Running` does not mean the service is ready. Use health checks and inspect logs.
- Tag release images with an immutable identifier such as a Git SHA; authenticate before pushing to a registry.

## 7. Model APIs and Deployment Patterns

An inference API is a stable contract around a model. Load the model once at process startup, validate request data, create features in the training-time order, call prediction, and return a documented JSON response. Test both a valid request and invalid/missing fields.

```bash
curl -s http://localhost:8085/health
curl -s -X POST http://localhost:8085/predict \
  -H 'Content-Type: application/json' \
  -d '{"features": [100.5, 12, 3]}'
```

Flask and FastAPI differ in routing and validation ergonomics, but both need correct bind host/port, startup behavior, error responses, and input validation. FastAPI request models make type and schema validation explicit. For batch prediction, preserve row order and write one prediction per input row.

### Serving patterns

- **Synchronous API:** request returns a prediction immediately; keep timeouts and payload sizes bounded.
- **Batch:** process a dataset in chunks, preserve feature columns, and write an auditable output.
- **Asynchronous worker:** enqueue a job, return a job ID, track queued/running/failed/complete state, and persist the result. Make retry behavior safe against duplicate work.
- **A/B test:** assign traffic to model variants and attribute outcomes to the variant that served them.
- **Canary:** send a small fraction of traffic to a new version, observe health and quality, then promote or roll back.
- **BentoML/Portainer/Compose:** verify the packaged model reference, image, ports, environment, volumes, health, and restart behavior after deployment.

Never promote a model solely because its process starts. Use an explicit quality gate and keep rollback available.

## 8. Metrics, Dashboards, and Alerts

Prometheus scrapes instrumented targets and stores time-series data. Grafana queries Prometheus as a data source and renders panels/alerts. The address must be reachable from Grafana's network context; in Compose, that is commonly the Prometheus service name and container port.

Useful PromQL patterns:

```promql
up
rate(http_requests_total[5m])
sum by (status) (rate(http_requests_total[5m]))
histogram_quantile(0.95, sum by (le) (rate(request_duration_seconds_bucket[5m])))
```

Use counters for cumulative events, gauges for values that rise/fall, and histograms for distributions such as request latency. Keep labels bounded; avoid user IDs or other unbounded values as labels. A dashboard needs populated data, sensible units, a useful time range, and queries that return the expected series/table shape.

For ML monitoring, distinguish:

- **Service health:** availability, latency, errors, throughput, resource use.
- **Data quality:** schema, nulls, invalid ranges, or broken inputs.
- **Drift:** change in feature/prediction distributions relative to a reference.
- **Model quality:** delayed ground-truth metrics such as accuracy, precision, recall, or business cost.

Evidently can compute data/model tests and reports; Prometheus/Grafana can expose or visualize operational signals and alert when a threshold is crossed. Validate the entire path: source metric/report, scrape/ingestion, query, alert rule, notification contact point, and policy routing. Test a known-bad case to ensure the gate actually fires.

## 9. CI, Releases, and GitOps

### CI with Gitea Actions

A workflow has triggers, jobs, steps, and a runner environment. Typical checks install dependencies, lint, test, validate data/config, and publish artifacts. A failed command must fail its job; avoid `|| true` or shell wrappers that hide exit status.

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: python -m pip install -r requirements.txt
      - run: ruff check src tests
      - run: python -m pytest tests -q
```

Gitea Actions is broadly compatible with common workflow syntax, but runner images, action availability, and secrets behavior can differ. Check the actual run logs. Matrix jobs must use their matrix values; artifact upload paths must exist. Pass secrets through the platform's secret mechanism and never echo them.

For reusable workflows, define callable inputs/secrets and trace them from caller to callee. For releases, build the package/image, apply an explicit version, publish to the intended registry, and verify the remote artifact. Branch protection should require the same check names the workflow reports. Reverting a bad release should create an auditable inverse change and rerun checks.

### GitOps with ArgoCD

Git is the desired state; ArgoCD continuously compares the cluster with a selected repository revision and path. Before syncing, inspect the rendered diff, destination namespace, image tags, and resource ownership. Prefer rollback through a new Git change so the deployed state remains reviewable.

## 10. Workflow Orchestration and Kubernetes

### Argo Workflows and Prefect

An Argo `Workflow` is a Kubernetes object. Its entrypoint selects a template; templates define container steps or DAG tasks. Use current pullable images, correct namespaces/service accounts, declared inputs/outputs, retries, and resource limits. A workflow being accepted is not proof that its pods succeeded; inspect phase, pod events, and logs.

For a DAG, each dependency must reference an existing task name and the graph must be acyclic. Output parameters need both a declared output path and a matching consumer expression. `withParam` expects a JSON array and passes each item to a template. A `CronWorkflow` adds schedule/time-zone and concurrency/history policies; check that it creates the expected Workflow.

Prefect distinguishes flows (orchestration) from tasks (tracked units of work). Check decorators, result passing, retries, and the behavior supported by the installed version.

### Kubernetes service and scaling basics

- **Deployment:** manages replica pods and rollout state.
- **Service:** selects pods by labels and provides a stable network endpoint.
- **Ingress/Gateway:** routes external traffic to services.
- **HPA:** scales a target workload based on resource/custom metrics.
- **PVC:** requests persistent storage for pods.
- **KServe InferenceService:** declares a model-serving endpoint and model storage/runtime.

For a Service, `port` is the service-facing port and `targetPort` is the pod/container port. Verify selectors and endpoints, not just the YAML. For an HPA, the target reference must match API version, kind, and workload name; metrics must be available. For KServe, confirm the `storageUri` points to an existing bucket/PVC and model path, then inspect predictor pod mount/download events.

```bash
kubectl get deploy,svc,pods -n <namespace>
kubectl get endpoints <service> -n <namespace>
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
kubectl describe hpa <name> -n <namespace>
```

For Kubeflow Pipelines, components exchange typed parameters and artifacts. Compile the pipeline, verify dependencies and artifact types, then inspect each component's run status and lineage in the UI.

## End-to-End MLOps System

A practical lifecycle joins these pieces:

1. **Version inputs:** code in Git, data in DVC/object storage, dependencies in a lockfile.
2. **Validate data:** schema and quality checks before training.
3. **Train reproducibly:** configuration, seeds, splits, code version, and dependencies recorded.
4. **Track and compare:** MLflow/DVC store parameters, metrics, artifacts, and run identity.
5. **Register and gate:** register a candidate; compare it to the champion using a declared metric and threshold.
6. **Serve:** deploy a versioned artifact behind a stable request contract.
7. **Observe:** collect service, data, and model-quality signals.
8. **Respond:** alert on incidents or trigger retraining; evaluate before promotion.
9. **Deploy with GitOps:** commit desired state and let the reconciler apply it with reviewable history.

At every handoff, record a stable identity: commit SHA, dataset/version, run ID, model version/alias, image tag, workflow run, or GitOps revision. If those identities cannot be traced, reproducing or rolling back the system becomes guesswork.

## Troubleshooting Checklist

Start at the nearest failing boundary and move outward:

1. **Is the process present?** Check process/container/pod status and exit code.
2. **Is it listening/ready?** Check bind host, port, health endpoint, readiness probe, or controller status.
3. **Can the caller reach it?** Test from the caller's network context; `localhost` means the current machine/container, not every service.
4. **Are names and contracts aligned?** Compare file paths, YAML keys, service labels/selectors, ports, feature columns, model URIs, and output names.
5. **Are dependencies and credentials available to the right process?** Check interpreter/image packages, mounted files, environment variables, permissions, and secret paths without printing secret values.
6. **Did the expected artifact/state change?** Inspect DVC status, MLflow run/artifact, registry alias, endpoints, workflow result, metrics, or deployment diff.
7. **Does a real request or run work?** Validate through the external interface, not only by reading configuration.

Avoid broad speculative edits. Reproduce the failure, use logs/events and the narrowest status command, change one likely cause, and repeat the same check.

## Day Map

Use this map to find the relevant chapter quickly; the README links every daily task and solution.

| Days | Main topics |
| --- | --- |
| 001-009 | Python environments, Jupyter, uv, Git hygiene, Make, linting, packaging, hooks, templates |
| 010-019 | DVC initialization, data/remotes, pipelines, parameters, metrics, experiments, branches |
| 020-030 | MLflow tracking, experiments, search, autologging, registry, signatures, projects, artifact stores, serving |
| 031-040 | Config, reproducibility, evaluation, cross-validation, tuning, model comparison, pipeline stages, parallelism, PyTorch, capstone |
| 041-049 | Feast, feature retrieval, Vault, Great Expectations, quality gates, integration |
| 050-056 | Docker images, multi-stage builds, Compose, PyTorch wheels, registries, health checks, image CI |
| 057-066 | Flask/FastAPI, batch serving, BentoML, Portainer, A/B tests, async workers, gateways, canaries, Compose serving |
| 067-075 | Prometheus/Grafana wiring, panels, drift, Evidently tests, alerts, dashboards, champion/challenger monitoring |
| 076-084 | CI lint/tests, data-quality jobs, matrix builds, artifacts, secrets, packages, reusable workflows, revert, branch protection |
| 085-091 | Argo Workflows, DAGs, parameters/branching, Prefect, fan-out, CronWorkflow, production pipeline with MLflow |
| 092-096 | Kubernetes Service/HPA, KServe, Kubeflow Pipelines, ArgoCD GitOps |
| 097-100 | End-to-end serving, monitoring/retraining, GitOps deployment, observability loop |

## Useful References

- [Python virtual environments](https://docs.python.org/3/library/venv.html)
- [DVC pipelines](https://dvc.org/doc/user-guide/pipelines)
- [MLflow tracking](https://mlflow.org/docs/latest/tracking.html)
- [Feast concepts](https://docs.feast.dev/getting-started/concepts)
- [Great Expectations](https://docs.greatexpectations.io/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Prometheus documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana documentation](https://grafana.com/docs/grafana/latest/)
- [Argo Workflows concepts](https://argo-workflows.readthedocs.io/en/latest/workflow-concepts/)
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/)
- [KServe documentation](https://kserve.github.io/website/)
- [ArgoCD documentation](https://argo-cd.readthedocs.io/en/stable/)