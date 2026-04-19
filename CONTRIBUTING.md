# Contributing

## Open Source Contributions from this Lab

Working hands-on with this Istio deployment led to a real contribution to the official Istio documentation.

### PR #17329 — istio/istio.io

**[docs: add note about expected IST0173 warnings when applying Bookinfo destination rules](https://github.com/istio/istio.io/pull/17329)**

**What was found:**

After following the standard Bookinfo getting started guide and applying `destination-rule-all.yaml`, running `istioctl analyze` produces the following errors:

```
Error [IST0173] (DestinationRule default/ratings) The Subset v2-mysql
defined in the DestinationRule does not select any pods. Which may lead
to 503 UH (NoHealthyUpstream).

Error [IST0173] (DestinationRule default/ratings) The Subset v2-mysql-vm
defined in the DestinationRule does not select any pods. Which may lead
to 503 UH (NoHealthyUpstream).
```

**Why this matters:**

The `destination-rule-all.yaml` file defines 4 subsets for the ratings service — `v1`, `v2`, `v2-mysql`, and `v2-mysql-vm`. However, the standard Bookinfo deployment only creates `ratings-v1`. The `v2-mysql` and `v2-mysql-vm` subsets require additional deployment steps that are not part of the standard guide.

Users who run `istioctl analyze` after following the getting started guide see these errors with no explanation, creating confusion about whether their installation is healthy.

**The fix:**

Added a `{{< tip >}}` note to the Bookinfo documentation page explaining that these IST0173 warnings are expected for a standard deployment and can be safely ignored unless the MySQL-based ratings variants have been deployed.

---

## How to Contribute to This Repo

If you find issues or improvements while working with this lab:

1. Fork the repo
2. Create a branch: `git checkout -b fix/your-fix-name`
3. Make your changes
4. Commit: `git commit -m "fix: description of your fix"`
5. Push and open a PR

If you find issues with Istio itself, consider contributing upstream:
- **Docs:** https://github.com/istio/istio.io
- **Code:** https://github.com/istio/istio
- **Good first issues:** https://github.com/istio/istio.io/contribute

---

*Ahmed Altuwaijari 
