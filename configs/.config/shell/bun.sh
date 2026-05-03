export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

case ":$PATH:" in
  *":$BUN_INSTALL/bin:"*)
    ;;
  *)
    export PATH="$BUN_INSTALL/bin:$PATH"
    ;;
esac
