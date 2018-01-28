import json
import os
import shutil
import subprocess
import sys


POINT_EXAMPLE = '[123.45, 0.95]'
JSON_EXAMPLE = '{{"points": [{example}]}}'.format(example=POINT_EXAMPLE)
TEMPO_SUFFIX = 'tempo'


def main(argv):
    yield banner('Validating', start_with_newlines=False)

    force = len(argv) == 4 and argv[3] == 'force'
    is_argv_valid = (
        len(argv) == 3 or
        force
    )

    if not is_argv_valid:
        message = (
            'Usage:\n'
            '    python sync.py VIDEO_FILE AUDIO_FILE JSON_FILE [force]\n'
            'Example:\n'
            '    python sync.py video.mp4 audio.aac points.json force\n'
            '\n'
            'Python 3.5 or later is required.'
        )
        yield (1, message)
        return

    video_file_path = argv[0]
    audio_file_path = argv[1]
    json_file_path = argv[2]

    (_, audio_extension) = os.path.splitext(audio_file_path)

    if not os.path.isfile(video_file_path):
        yield (1, '{file} is not an existing file.'.format(
            file=video_file_path,
        ))
        return

    if not os.path.isfile(audio_file_path):
        yield (1, '{file} is not an existing file.'.format(
            file=audio_file_path,
        ))
        return

    if not os.path.isfile(json_file_path):
        yield (1, '{file} is not an existing file.'.format(
            file=json_file_path,
        ))
        return

    dir = os.path.join(
        os.path.dirname(video_file_path),
        '{file}-output'.format(file=os.path.basename(video_file_path))
    )

    if not force and os.path.exists(dir):
        message = (
            '{dir} already exists. Move or delete it first.\n'
            'Alternatively, add `force` at the end of the command.'
            .format(
                dir=dir,
            )
        )
        yield (1, message)
        return

    try:
        subprocess.run(['ffmpeg', '-version'])
    except FileNotFoundError:
        yield (1, 'ffmpeg seems not to be installed.')
        return

    def json_parse_error(message):
        message = 'Failed to parse for "points" in {file}\n{message}'.format(
            file=json_file_path,
            message=message,
        )
        return (1, message)

    with open(json_file_path) as json_file:
        try:
            json_data = json.load(json_file)
        except json.decoder.JSONDecodeError as exception:
            yield json_parse_error(exception)
            return

    raw_points = (json_data or {}).get('points')

    if not raw_points or not isinstance(raw_points, list):
        yield json_parse_error(
            'Expected for example `{example}` (at least one point) but got:\n'
            '{actual}'
            .format(
                example=JSON_EXAMPLE,
                actual=json_data,
            )
        )
        return

    for index, point in enumerate(raw_points):
        is_valid = (
            isinstance(point, list) and
            len(point) == 2 and
            is_number(point[0]) and
            is_number(point[1])
        )

        if not is_valid:
            yield json_parse_error(
                'Expected point {num} to be for example `{example}` but got:\n'
                '{actual}'
                .format(
                    num=index + 1,
                    example=POINT_EXAMPLE,
                    actual=point,
                )
            )
            return

        if not (point[0] > 0):
            yield json_parse_error(
                'Expected point {num} to have a duration > 0 but got:\n'
                '{actual}'
                .format(
                    num=index + 1,
                    actual=point[0],
                )
            )
            return

        if not (0.5 <= point[1] <= 2.0):
            yield json_parse_error(
                'Expected point {num} to have 0.5 <= tempo <= 2.0 but got:\n'
                '{actual}'
                .format(
                    num=index + 1,
                    actual=point[1],
                )
            )
            return

    # Add a special point at the end that goes on to the end of the audio.
    points = [(point[0], point[1]) for point in raw_points] + [(0, 1)]

    yield banner('Cutting audio')

    if force:
        shutil.rmtree(dir, ignore_errors=True)
    os.makedirs(dir)

    elapsed = 0

    for index, (duration, tempo) in enumerate(points):
        # Handle the special “end” point mentioned above.
        end = duration == 0
        subprocess.run(filter(None, [
            'ffmpeg',
            '-i',
            audio_file_path,
            '-ss',
            str(to_seconds(elapsed)),
            None if end else '-t',
            None if end else str(to_seconds(duration)),
            '-acodec',
            'copy',
            '-strict',
            'experimental',
            part_name(dir, index, audio_extension),
        ]))
        elapsed += duration

    yield banner('Changing tempo')

    for index, (duration, tempo) in enumerate(points):
        input = part_name(dir, index, audio_extension)
        output = part_name(dir, index, audio_extension, suffix=TEMPO_SUFFIX)

        if tempo == 1:
            shutil.copyfile(input, output)
        else:
            subprocess.run([
                'ffmpeg',
                '-i',
                input,
                '-filter:a',
                'atempo={}'.format(tempo),
                '-strict',
                'experimental',
                output,
            ])

    yield banner('Concatenating audio')

    input_file_path = os.path.join(dir, 'concat_input.txt')
    input_file_contents = '\n'.join([
        "file '{file}'".format(
            file=part_name('.', index, audio_extension, suffix=TEMPO_SUFFIX),
        )
        for index in range(len(points))
    ])

    with open(input_file_path, 'w') as input_file:
        input_file.write(input_file_contents + '\n')

    concat_file_path = os.path.join(dir, 'concat{}'.format(audio_extension))

    subprocess.run([
        'ffmpeg',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        input_file_path,
        '-c',
        'copy',
        '-strict',
        'experimental',
        concat_file_path,
    ])

    yield banner('Generating new video')

    output_file_path = os.path.join(dir, os.path.basename(video_file_path))

    subprocess.run([
        'ffmpeg',
        '-i',
        concat_file_path,
        '-i',
        video_file_path,
        '-c:v',
        'copy',
        '-strict',
        'experimental',
        output_file_path,
    ])

    yield banner('Done')

    yield (0, 'Successfully generated {dir}/'.format(dir=dir))
    return


def part_name(dir, index, audio_extension, suffix=None):
    return os.path.join(dir, '{index}{suffix}{extension}'.format(
        index=index,
        suffix='' if suffix is None else '_{}'.format(suffix),
        extension=audio_extension,
    ))


def banner(message, start_with_newlines=True):
    bar = '#' * 60
    message = '\n'.join(filter(None, [
        '\n\n' if start_with_newlines else None,
        bar,
        message,
        bar,
    ]))
    return (None, message)


def is_number(x):
    return isinstance(x, (int, float)) and not isinstance(x, bool)


def to_seconds(milliseconds):
    return milliseconds / 1000


if __name__ == '__main__':
    for exit_code, message in main(sys.argv[1:]):
        if message is not None:
            print(message)
        if exit_code is not None:
            if exit_code != 0:
                print('Failed to sync.')
            sys.exit(exit_code)

    print('The program exited unexpectedly.')
    sys.exit(2)
