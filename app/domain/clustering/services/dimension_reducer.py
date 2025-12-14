# frozen_string_literal: true
import sys
import os
import json
import argparse
import numpy as np
from sklearn.decomposition import PCA


DEFAULT_MEAN_PATH = os.environ.get("PCA_MEAN_PATH", "app/domain/clustering/services/pca_mean.json")
DEFAULT_COMP_PATH = os.environ.get("PCA_COMPONENTS_PATH", "app/domain/clustering/services/pca_components.json")


class PCAParamsError(Exception):
    pass


def eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def read_stdin_json():
    raw = sys.stdin.read().strip()
    if not raw:
        return None
    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        raise PCAParamsError(f"Invalid JSON on stdin: {e}") from e


def ensure_matrix(vectors):
    if not isinstance(vectors, list) or len(vectors) == 0:
        raise PCAParamsError("Expected a non-empty list of vectors.")

    if not isinstance(vectors[0], list):
        raise PCAParamsError("Expected list-of-vectors for PCA fit mode.")

    try:
        X = np.array(vectors, dtype=float)
    except Exception as e:
        raise PCAParamsError(f"Vectors contain non-numeric values: {e}") from e

    if X.ndim != 2:
        raise PCAParamsError(f"Expected 2D matrix, got shape {X.shape}.")

    if X.shape[0] < 2:
        raise PCAParamsError("Need at least 2 samples to fit PCA.")

    if X.shape[1] < 2:
        raise PCAParamsError("Embedding dimension must be >= 2.")

    if not np.all(np.isfinite(X)):
        raise PCAParamsError("Vectors contain NaN/Inf.")

    # verify consistent dims (np.array already enforces rectangular, but keep explicit)
    d = X.shape[1]
    if any(len(v) != d for v in vectors):
        raise PCAParamsError("Inconsistent embedding dimensions in input list.")

    return X


def ensure_vector(vec):
    if not isinstance(vec, list):
        raise PCAParamsError("Expected a single embedding vector as a JSON list.")
    try:
        v = np.array(vec, dtype=float)
    except Exception as e:
        raise PCAParamsError(f"Vector contains non-numeric values: {e}") from e
    if v.ndim != 1:
        raise PCAParamsError(f"Expected 1D vector, got shape {v.shape}.")
    if v.size < 2:
        raise PCAParamsError("Embedding dimension must be >= 2.")
    if not np.all(np.isfinite(v)):
        raise PCAParamsError("Vector contains NaN/Inf.")
    return v


def write_params(mean_path, comp_path, mean, components):
    # store as dicts for future-proofing
    mean_obj = {"mean": mean.tolist()}
    comp_obj = {"components": components.tolist()}  # shape (2, d)

    try:
        os.makedirs(os.path.dirname(mean_path), exist_ok=True)
        os.makedirs(os.path.dirname(comp_path), exist_ok=True)
        with open(mean_path, "w", encoding="utf-8") as f:
            json.dump(mean_obj, f)
        with open(comp_path, "w", encoding="utf-8") as f:
            json.dump(comp_obj, f)
    except OSError as e:
        raise PCAParamsError(f"Failed to write PCA params: {e}") from e


def load_params(mean_path, comp_path):
    if not os.path.exists(mean_path):
        raise PCAParamsError(f"Missing PCA mean file: {mean_path}")
    if not os.path.exists(comp_path):
        raise PCAParamsError(f"Missing PCA components file: {comp_path}")

    try:
        with open(mean_path, "r", encoding="utf-8") as f:
            mean_obj = json.load(f)
        with open(comp_path, "r", encoding="utf-8") as f:
            comp_obj = json.load(f)
    except Exception as e:
        raise PCAParamsError(f"Failed to read PCA params JSON: {e}") from e

    mean_list = mean_obj["mean"] if isinstance(mean_obj, dict) and "mean" in mean_obj else mean_obj
    comp_list = comp_obj["components"] if isinstance(comp_obj, dict) and "components" in comp_obj else comp_obj

    mean = ensure_vector(mean_list)
    comps = np.array(comp_list, dtype=float)

    if comps.ndim != 2:
        raise PCAParamsError(f"Components must be 2D, got shape {comps.shape}")

    # allow d x 2 (transpose)
    if comps.shape[0] == mean.size and comps.shape[1] == 2:
        comps = comps.T

    if comps.shape[0] != 2:
        raise PCAParamsError(f"Components must have 2 rows, got shape {comps.shape}")

    if comps.shape[1] != mean.size:
        raise PCAParamsError(f"Dim mismatch: mean length {mean.size}, components {comps.shape}")

    if not np.all(np.isfinite(comps)):
        raise PCAParamsError("Components contain NaN/Inf.")

    return mean, comps


def project(vec_or_vectors, mean, comps):
    # single vector
    if isinstance(vec_or_vectors, list) and (len(vec_or_vectors) == 0 or not isinstance(vec_or_vectors[0], list)):
        v = ensure_vector(vec_or_vectors)
        if v.size != mean.size:
            raise PCAParamsError(f"Embedding dim {v.size} != PCA dim {mean.size}")
        xy = (v - mean) @ comps.T
        return [float(xy[0]), float(xy[1])]

    # list of vectors
    if not isinstance(vec_or_vectors, list):
        raise PCAParamsError("Expected list or list-of-lists for transform.")
    out = []
    for i, vec in enumerate(vec_or_vectors):
        if not isinstance(vec, list):
            raise PCAParamsError(f"Element {i} is not a vector list.")
        v = ensure_vector(vec)
        if v.size != mean.size:
            raise PCAParamsError(f"Embedding dim mismatch at index {i}: {v.size} != {mean.size}")
        xy = (v - mean) @ comps.T
        out.append([float(xy[0]), float(xy[1])])
    return out


def fit_mode(vectors, mean_path, comp_path):
    X = ensure_matrix(vectors)
    pca = PCA(n_components=2)
    Z = pca.fit_transform(X)

    # Save params
    write_params(mean_path, comp_path, pca.mean_, pca.components_)

    return Z.tolist()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fit", action="store_true", help="Fit PCA on list-of-vectors and save mean/components.")
    parser.add_argument("--mean-path", default=DEFAULT_MEAN_PATH)
    parser.add_argument("--components-path", default=DEFAULT_COMP_PATH)
    args = parser.parse_args()

    data = read_stdin_json()
    if data is None:
        print(json.dumps([]))
        return

    if args.fit:
        result = fit_mode(data, args.mean_path, args.components_path)
        print(json.dumps(result))
        return

    # transform mode
    mean, comps = load_params(args.mean_path, args.components_path)
    result = project(data, mean, comps)
    print(json.dumps(result))


if __name__ == "__main__":
    try:
        main()
    except PCAParamsError as e:
        eprint(f"PCA error: {e}")
        sys.exit(2)
    except Exception as e:
        eprint(f"Unexpected error: {e}")
        sys.exit(3)
