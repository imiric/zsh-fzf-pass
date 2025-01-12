function fuzzy-pass() {
  PASS_STR_VALID_DIR="${PASSWORD_STORE_DIR:-${HOME}/.password-store}"
  FZF_ARGS=("--select-1" "--exit-0" "--height=25%" "--reverse" "--tac" "--no-sort")
  PASSFILE=$(find -L $PASS_STR_VALID_DIR | sed "s|$PASS_STR_VALID_DIR||" | grep '.gpg' | sed 's/.gpg$//g' | fzf "${FZF_ARGS[@]}")

  [ -z "$PASSFILE" ] && return 0

  PASSDATA="$(pass ${PASSFILE})"
  PASS="$(echo "${PASSDATA}" | head -n 1)"
  LOGIN="$(echo "${PASSDATA}" | egrep -i "login:|username:|user:" | head -n 1 | cut -d' ' -f2-)"
  if [ -z "${LOGIN}" ] && [ -n "${PASS}" ]; then
    LOGIN=${PASSFILE##*/}
  fi
  EMAIL="$(echo "${PASSDATA}" | egrep -i "email:" | head -n 1 | cut -d' ' -f2-)"
  URL="$(echo "${PASSDATA}" | egrep -i "url:" | cut -d' ' -f2-)"
  if [ -z "${URL}" ]; then
    URL="$(basename $(dirname "${PASSFILE}"))"
    URL="$(echo "${URL}" | grep "\.")"
  fi

  ACTIONS="Edit\nFile"

  if [ -n "${URL}" ]; then
    ACTIONS="URL\n${ACTIONS}"
  fi
  if [ -n "${EMAIL}" ]; then
    ACTIONS="Email\n${ACTIONS}"
  fi
  if [ -n "${PASS}" ]; then
    ACTIONS="Password\n${ACTIONS}"
  fi
  if [ -n "${LOGIN}" ]; then
    ACTIONS="Login\n${ACTIONS}"
  fi

  CONTINUE=true

  while ${CONTINUE}; do
    ACTION=$(echo "${ACTIONS}" \
      | fzf --header "Pass file ${PASSFILE}" "${FZF_ARGS[@]}")
    case ${ACTION} in
      Login)
        echo "${LOGIN}" | clipcopy
        echo "Copied Login '${LOGIN}' to clipboard"
        ;;
      Password)
        pass --clip "${PASSFILE}" 1>/dev/null
        echo "Copied Password to clipboard (clear in 45 seconds)"
        ;;
      URL)
        echo "${URL}" | clipcopy
        echo "Copied Url '${URL}' to clipboard"
        ;;
      File)
        pass "${PASSFILE}"
        ;;
      Email)
        echo "${EMAIL}" | clipcopy
        echo "Copied Email '${EMAIL}' to clipboard"
        ;;
      Edit)
        pass edit "${PASSFILE}"
        ;;
      *)
        CONTINUE=false
        ;;
    esac
  done

}

alias fzp=fuzzy-pass
