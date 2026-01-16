# tamarin-prover-nix

Nix flake for development in Tamarin-Prover:

## Building tamarin:

Use `nix build .` in top-level directiory. Employs `frontend/flake.nix` to
build interactive graph stuff using node; then builds tamarin.

If you need a certain version of tamarin, fork this repository and modify,
[flake.nix](flake.nix). Most of the time you just modify `tamarinRev` to a tag
of specific commit.

## Developing in Tamarin

Install [ nix-direnv ]( https://github.com/nix-community/nix-direnv )
and
in your .envrc, put

```
use flake "github:rkunnema/tamarin-prover-nix/dev-shell"
```

## Contributing

I am no nix expert and I am happy to get help via PRs. If I am too slow for
you, fork this repository , this is really just to share work I once did. Let
me know when you do though, then I can link to it.

