// Copyright 2019 SUSE Gmbh.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"encoding/json"
	"fmt"

	"k8s.io/api/batch/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"sigs.k8s.io/kustomize/v3/pkg/hasher"
	"sigs.k8s.io/kustomize/v3/pkg/ifc"
	"sigs.k8s.io/kustomize/v3/pkg/resmap"
	"sigs.k8s.io/kustomize/v3/pkg/resource"
	"sigs.k8s.io/kustomize/v3/pkg/types"
	"sigs.k8s.io/yaml"
)

// GroupHashTransformer adds a hash to the name of selected resources.
// Supports Jobs, Secrets, and ConfigMaps.
type plugin struct {
	hasher     ifc.KunstructuredHasher
	Target     *types.Selector `json:"target" yaml:"target"`
}

//noinspection GoUnusedGlobalVariable
var KustomizePlugin plugin

func (p *plugin) Config(
	ldr ifc.Loader, rf *resmap.Factory, c []byte) (err error) {
		p.hasher = rf.RF().Hasher()
		err = yaml.Unmarshal(c, p)
        if err != nil {
            return err
        }
		return nil
}

func (p *plugin) Transform(m resmap.ResMap) error {	
	var resources []*resource.Resource
	if (p.Target != nil ) {
		var err error
		resources, err = m.Select(*p.Target)
		if err != nil {
			return err
		}
	} else {
		resources = m.Resources()
	}

	for _, r := range resources {
		hash, err := p.Hash(r)
		if err != nil {
			return err
		}
		r.SetName(fmt.Sprintf("%s-%s", r.GetName(), hash))
	}
	return nil
}

func (p *plugin) Hash(m ifc.Kunstructured) (string, error) {
	u := unstructured.Unstructured{
		Object: m.Map(),
	}
	kind := u.GetKind()
	switch kind {
	case "Job":	
			job, err := unstructuredToJob(u)
			if err != nil {
					return "", err
			}
			return jobHash(job)
	default:
			return p.hasher.Hash(m)
	}
}

func jobHash(job *v1.Job) (string, error) {
	encoded, err := encodeJob(job)
	if err != nil {
			return "", err
	}
	h, err := hasher.Encode(hasher.Hash(encoded))
	if err != nil {
			return "", err
	}
	return h, nil
}

func encodeJob(job *v1.Job) (string, error) {
	// json.Marshal sorts the keys in a stable order in the encoding
	m := map[string]interface{}{
		"kind": "Job",
		"name": job.Name, 
		"spec": job.Spec}
	data, err := json.Marshal(m)
	if err != nil {
			return "", err
	}
	return string(data), nil
}

func unstructuredToJob(u unstructured.Unstructured) (*v1.Job, error) {
	marshaled, err := json.Marshal(u.Object)
	if err != nil {
			return nil, err
	}
	var out v1.Job
	err = json.Unmarshal(marshaled, &out)
	return &out, err
}