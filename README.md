# checkrun-timechart-action
A GitHub Action that displays a timechart of CheckRuns related to a given sha. Useful for debugging the performance of GitHub Actions workflows. Uses the legendary [`bt.sh`](https://github.com/simonsj/bt.sh) for ASCII timechart display.

## Example output

```
[    5.000s ] ├──┤                                                       * YAMBURGER
[    0.000s ]  .                                                         * kubevalidator
[    8.000s ]             ├────┤                                         * kubectl-diff (code)
[    7.000s ]             ├───┤                                          * kubectl-diff (cameras)
[   10.000s ]               ├──────┤                                     * kubectl-diff (geryon)
[   10.000s ]               ├──────┤                                     * kubectl-diff (kubernetes-dashboard)
[    0.000s ]               .                                            * deploy-label
[   80.762s ]                ├─────────────────────────────────────────┤ * bt
[    0.000s ]                .                                           * deploy
[    0.000s ]                .                                           * kubectl-apply
[    0.000s ]                .                                           * required-builds
[    8.000s ]                         ├────┤                             * kubectl-diff (home-assistant)
[    8.000s ]                         ├────┤                             * kubectl-diff (motion)
[   11.000s ]                           ├──────┤                         * kubectl-diff (kube-system)
[    8.000s ]                           ├────┤                           * kubectl-diff (mysql)
[    6.000s ]                                     ├──┤                   * kubectl-diff (unifi)
[    0.000s ]                                                     .      * diff

     one '.' unit is less than:    1.249s
                    total time:   71.522s
```

## Usage

This action can be run as the last step in a workflow:

```yaml
      - name: checkrun-timechart
        uses: urcomputeringpal/checkrun-timechart-action@v0.0.3
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
        with:
          SHA: "${{ github.event.pull_request.head.sha }}"
          TRACE_START: "${{ github.event.pull_request.updated_at }}"
```

OR as a separate workflow entirely using a preceeding step that waits for other CheckRuns to complete:

```yaml
name: checkrun-timechart
on:
  pull_request:
    types: [synchronize]

jobs:
  checkrun-timechart:
    runs-on: ubuntu-latest
    steps:
      - name: wait
        uses: "WyriHaximus/github-action-wait-for-status@4c9e58820905eb246e88a413c39a9104cccf7e80"
        with:
          ignoreActions: checkrun-timechart
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"

      - name: checkrun-timechart
        uses: urcomputeringpal/checkrun-timechart-action@v0.0.3
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
        with:
          SHA: "${{ github.event.pull_request.head.sha }}"
          TRACE_START: "${{ github.event.pull_request.updated_at }}"
```