#!/usr/bin/env python3

import signal
import sys
import time
import typing
from dataclasses import dataclass, field
from time import sleep

from arcaflow_plugin_sdk import plugin, validation


@dataclass
class InputParams:
    seconds: typing.Annotated[float, validation.min(0.0)] = field(
       metadata={
           "id": "seconds",
           "name": "seconds",
           "description": "number of seconds to wait as a floating point "
                          "number for subsecond precision."
       }
    )


@dataclass
class SuccessOutput:
    """
    This is the output data structure for the success case.
    """
    message: str


@dataclass
class ErrorOutput:
    """
    This is the output data structure in the error  case.
    """
    error: str



@plugin.step(
    id="wait",
    name="Wait",
    description="Waits for the given amount of time",
    outputs={"success": SuccessOutput, "error": ErrorOutput},
)
def wait(
    params: InputParams
) -> typing.Tuple[str, typing.Union[SuccessOutput, ErrorOutput]]:
    """
    :param params:

    :return: the string identifying which output it is,
             as well the output structure
    """
    start_time = time.time()
    try:
        sleep(params.seconds)
        if finished_early:
            return "aborted-incorrectly", ErrorOutput(
                "Aborted {:0.2f} seconds after being scheduled to wait for {} seconds."
                    .format(time.time() - start_time, params.seconds)
            )
        else:
            return "success", SuccessOutput(
                "Waited {:0.2f} seconds after being scheduled to wait for {} seconds."
                    .format(time.time() - start_time, params.seconds)
            )
    except BaseException as ex:
        if EARLY_EXIT_KEY in ex:
            return "aborted", ErrorOutput(
                "Aborted {:0.2f} seconds after being scheduled to wait for {} seconds."
                    .format(time.time() - start_time, params.seconds)
            )
        else:
            return "error", ErrorOutput(
                "Failed waiting for {} seconds. Took {:0.2f} seconds."
                    .format(params.seconds, time.time() - start_time)
            )


EARLY_EXIT_KEY = "early-exit"
finished_early = False


def exit_early(*args):
    finished_early = True
    raise Exception(EARLY_EXIT_KEY)


if __name__ == "__main__":
    signal.signal(signal.SIGINT, exit_early)
    signal.signal(signal.SIGTERM, exit_early)

    sys.exit(plugin.run(plugin.build_schema(
        wait,
    )))
