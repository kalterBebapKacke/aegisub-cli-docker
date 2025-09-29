# aegisub-cli-docker

This is a project to revive aegisub-cli with a new and lightweigt docker. 

The current docker is working and has a size of ~860MB and comes with Dependency Control and Shapery preinstalled.

## Notes
The command to install Dependency Control is 
`aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button":0,"values":{"macro":"DependencyControl"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script" || true`

When installing other packages with DepCTl it is adviced to use `|| true` at the end of the command, as aegisub yields an `Segmentation Error` by default as it has no gui to use certain api's on. This error can be fixed by installing `wxWidgets`, but the increase in size is not worth the fix.