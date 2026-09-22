# Olympic Participation Tracker

## Context

The **Olympic Participation Tracker** is an application designed to record and analyze countries' participation in the Olympic Games. It provides statistics on medals obtained by each country, helping users gain insights into historical performance. Although the application is currently in its early development stages, we aim to create a robust and user-friendly tool for Olympic enthusiasts.

## Technical Context

The application is built using **Angular 20** and relies on **npm** for package management. Angular offers a powerful framework for creating dynamic web applications, and npm simplifies the process of managing dependencies and scripts.

Summary:

- **Node.js**: Version 24 in CI and in the Docker build
- **NGINX**: Unprivileged NGINX image, listening on port 8080 in Docker

## Getting Started

### Install dependencies

Run `npm i` in local development to install NodeJS dependencies. If you are installing the app on a CI environment prefer to use `npm ci`. you can also change npm cache directory to your working directory as following

```bash
npm ci --cache .npm --prefer-offline
```

## Development server

Run `npm start` for a dev server. Navigate to `http://localhost:4200/`. The application will automatically reload if you change any of the source files.

### Build

Run `npm run build` to build the project. The build artifacts will be stored in the `dist/` directory.

### Test

To run tests and ensure the application's functionality, use the following command:

```bash
npm test
```

Our test suite covers critical components, ensuring stability and reliability.

### Test script used by CI

The repository provides a portable test script used by GitHub Actions:

```bash
bash ./run-tests.sh
```

For this npm project, the script:

1. checks that npm is available;
2. runs `npm ci` when dependencies are missing;
3. runs `npm test`;
4. copies JUnit XML reports from `reports/` to `test-results/`.

The `test-results/` directory is the common report location consumed by the CI workflow. GitHub Actions publishes the results in GitHub Checks and retains the XML files as workflow artifacts, including when a test fails.

### Packaging

To package the application for distribution, run:

```bash
npm pack
```

This will create a distributable package containing the compiled code and necessary assets.

### Deploy on nginx

The `Dockerfile` builds the Angular application and serves the generated static files with the Nginx configuration in `nginx/`. It exposes the application on port 8080:

```bash
docker build -t olympic-participation-tracker .
docker run --rm -p 8080:8080 olympic-participation-tracker
```

## CI/CD

The GitHub Actions workflow in `.github/workflows/ci.yml` runs for pull requests targeting `main` and for pushes to `main`.

### Pull requests to `main`

- Runs unit tests and publishes the JUnit report.
- Builds the Docker image to validate the `Dockerfile`.
- Does not push an image or create a release.

### Pushes to `main`

- Runs the same tests.
- Builds and pushes the Docker image to GitHub Container Registry (GHCR).
- Creates a provenance attestation for the published image.
- Runs semantic-release after a successful image build.

semantic-release analyses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) to determine whether a release is required:

- `fix: ...` creates a patch release;
- `feat: ...` creates a minor release;
- `feat!: ...` or a `BREAKING CHANGE:` footer creates a major release.

When a release is created, semantic-release updates `package.json` and `package-lock.json`, generates `CHANGELOG.md`, creates a Git tag and GitHub Release, then adds the semantic version as an additional tag to the Docker image. Commits such as `docs:` or `ci:` alone do not create a release.

The workflow uses the automatically provided `GITHUB_TOKEN`; its permissions are scoped per job and the token is never printed in logs.

### Docker Image Tags in GitHub Container Registry

Images are published under:

```text
ghcr.io/bartsam/oc-p6-front
```

Every push to `main` produces a commit-specific image tag:

```text
ghcr.io/bartsam/oc-p6-front:main-<commit-sha>
```

When semantic-release creates a release, the same image also receives a semantic version tag, for example:

```text
ghcr.io/bartsam/oc-p6-front:<version>
```
