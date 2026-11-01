"""Open a same-directory terminal, then join its source Niri column as a tab."""

import json
import os
import socket
import subprocess
import sys
import time
import uuid

from kittens.tui.handler import result_handler
from kitty.constants import config_dir, kitty_exe


def niri(request):
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(5)
        connection.connect(os.environ["NIRI_SOCKET"])
        connection.sendall(json.dumps(request).encode() + b"\n")
        with connection.makefile("r") as stream:
            response = json.loads(stream.readline())
    if "Err" in response:
        raise RuntimeError(response["Err"])
    return response["Ok"]


def action(name, **arguments):
    return niri({"Action": {name: arguments}})


def kitty(*arguments):
    # Kitty gives background helpers a private remote-control socket descriptor.
    address = os.environ["KITTY_LISTEN_ON"]
    descriptors = (int(address[3:]),) if address.startswith("fd:") else ()
    return subprocess.check_output(
        [kitty_exe(), "@", "--to", address, *arguments],
        text=True,
        pass_fds=descriptors,
        timeout=5,
    ).strip()


def group_terminal(source_window_id):
    source = niri("FocusedWindow")["FocusedWindow"]
    marker = "niri-group-" + uuid.uuid4().hex
    new_kitty_id = None
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(5)
        connection.connect(os.environ["NIRI_SOCKET"])
        connection.sendall(b'"EventStream"\n')
        with connection.makefile("r") as stream:
            response = json.loads(stream.readline())
            if "Err" in response:
                raise RuntimeError(response["Err"])
            try:
                new_kitty_id = kitty(
                    "launch", "--type=os-window", "--cwd=current",
                    "--source-window=id:" + str(source_window_id),
                    "--title=" + marker,
                )
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    connection.settimeout(max(0.01, deadline - time.monotonic()))
                    line = stream.readline()
                    if not line:
                        raise RuntimeError("Niri closed its event stream")
                    event = json.loads(line)
                    window = event.get("WindowOpenedOrChanged", {}).get("window", {})
                    if window.get("title") != marker:
                        continue
                    windows = niri("Windows")["Windows"]
                    original = next((w for w in windows if source and w["id"] == source["id"]), None)
                    created = next((w for w in windows if w["id"] == window["id"]), None)
                    # Only consume when the new window is directly to the right
                    # of its original column. Never consume an unrelated window.
                    if not original or not created or original["is_floating"] or created["is_floating"]:
                        return
                    old_pos = original["layout"]["pos_in_scrolling_layout"]
                    new_pos = created["layout"]["pos_in_scrolling_layout"]
                    if original["workspace_id"] != created["workspace_id"] or new_pos[0] != old_pos[0] + 1:
                        return
                    action("ConsumeOrExpelWindowLeft", id=created["id"])
                    action("FocusWindow", id=created["id"])
                    action("SetColumnDisplay", display="Tabbed")
                    return
                raise TimeoutError("The new terminal did not appear in Niri")
            finally:
                if new_kitty_id:
                    # Restore the shell's title after using it to identify the window.
                    kitty("set-window-title", "--match=id:" + new_kitty_id)


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    path = os.path.join(config_dir, "niri_group.py")
    code = "import runpy; runpy.run_path(" + repr(path) + ", run_name='__main__')"
    boss.run_background_process(
        [kitty_exe(), "+runpy", code, str(target_window_id)],
        allow_remote_control=True,
    )


if __name__ == "__main__":
    group_terminal(int(sys.argv[1]))
