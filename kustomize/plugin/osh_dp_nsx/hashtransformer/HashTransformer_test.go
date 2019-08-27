// Copyright 2019 SUSE Gmbh.
// SPDX-License-Identifier: Apache-2.0
package main_test

import (
	"testing"

	"sigs.k8s.io/kustomize/v3/pkg/kusttest"
	plugins_test "sigs.k8s.io/kustomize/v3/pkg/plugins/test"
)

func TestHashTransformer(t *testing.T) {
	tc := plugins_test.NewEnvForTest(t).Set()
	defer tc.Reset()

	tc.BuildGoPlugin(
		"osh_dp_nsx", "", "HashTransformer")

	th := kusttest_test.NewKustTestPluginHarness(t, "/app")

  rm := th.LoadAndRunTransformer(`
apiVersion: osh_dp_nsx
kind: HashTransformer
metadata:
  name: hash-test
target:
  kind: Job
always: true
`, `
apiVersion: batch/v1
kind: Job
metadata:
  name: add-hash
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: not-selected
`)
  
    th.AssertActualEqualsExpected(rm, `
apiVersion: batch/v1
kind: Job
metadata:
  name: add-hash-hkthkt25f9
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: not-selected
`)
}