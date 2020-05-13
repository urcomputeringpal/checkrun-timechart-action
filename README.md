# checkrun-timechart-action
A GitHub Action that displays a timechart of CheckRuns related to a given sha. Useful for debugging the performance of GitHub Actions workflows. Uses the legendary [`bt.sh`](https://github.com/simonsj/bt.sh) for ASCII timechart display.

## Example output

```
[    5.000s ] ├──┤                                                                             * YAMBURGER
33
[    0.000s ]  .                                                                               * kubevalidator
34
[    8.000s ]             ├────┤                                                               * kubectl-diff (code)
35
[    7.000s ]             ├───┤                                                                * kubectl-diff (cameras)
36
[   10.000s ]               ├──────┤                                                           * kubectl-diff (geryon)
37
[   10.000s ]               ├──────┤                                                           * kubectl-diff (kubernetes-dashboard)
38
[    0.000s ]               .                                                                  * deploy-label
39
[   80.762s ]                ├───────────────────────────────────────────────────────────────┤ * bt
40
[    0.000s ]                .                                                                 * deploy
41
[    0.000s ]                .                                                                 * kubectl-apply
42
[    0.000s ]                .                                                                 * required-builds
43
[    8.000s ]                         ├────┤                                                   * kubectl-diff (home-assistant)
44
[    8.000s ]                         ├────┤                                                   * kubectl-diff (motion)
45
[   11.000s ]                           ├──────┤                                               * kubectl-diff (kube-system)
46
[    8.000s ]                           ├────┤                                                 * kubectl-diff (mysql)
47
[    6.000s ]                                     ├──┤                                         * kubectl-diff (unifi)
48
[    0.000s ]                                                     .                            * diff
49

50
     one '.' unit is less than:    1.249s
51
                    total time:   99.975s
```

## Usage

This action can be run as the last step in a workflow:

```yaml
      - name: checkrun-timechart
        uses: urcomputeringpal/checkrun-timechart-action
        with:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
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
  bt:
    runs-on: ubuntu-latest
    steps:
      - name: wait
        id: waitforstatuschecks
        uses: "WyriHaximus/github-action-wait-for-status@4c9e58820905eb246e88a413c39a9104cccf7e80"
        with:
          ignoreActions: checkrun-timechart
        env:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"

      - name: checkrun-timechart
        uses: urcomputeringpal/checkrun-timechart-action
        with:
          GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
          SHA: "${{ github.event.pull_request.head.sha }}"
          TRACE_START: "${{ github.event.pull_request.updated_at }}"
```