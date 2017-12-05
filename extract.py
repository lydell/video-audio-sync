import os
import subprocess
import sys


def main(argv):
    yield banner('Validating', start_with_newlines=False)

    if len(argv) != 2:
        message = (
            'Usage:\n'
            '    python extract.py VIDEO_FILE AUDIO_EXTENSION\n'
            'Example:\n'
            '    python extract.py video.mp4 aac\n'
            '\n'
            'Python 3.5 or later is required.'
        )
        yield (1, message)
        return

    video_file_path = argv[0]
    audio_extension = '.{extension}'.format(extension=argv[1])

    if not os.path.isfile(video_file_path):
        yield (1, '{file} is not an existing file.'.format(
            file=video_file_path,
        ))
        return

    (video_base, video_extension) = os.path.splitext(video_file_path)

    output_video_file_path = '{base}_video{extension}'.format(
        base=video_base,
        extension=video_extension,
    )

    output_audio_file_path = '{base}_audio{extension}'.format(
        base=video_base,
        extension=audio_extension,
    )

    # ffmpeg asks if you want to overwrite already existing files.

    try:
        subprocess.run(['ffmpeg', '-version'])
    except FileNotFoundError:
        yield (1, 'ffmpeg seems not to be installed.')
        return

    yield banner('Extracting video')

    subprocess.run([
        'ffmpeg',
        '-i',
        video_file_path,
        '-vcodec',
        'copy',
        '-an',
        output_video_file_path,
    ])

    yield banner('Extracting audio')

    subprocess.run([
        'ffmpeg',
        '-i',
        video_file_path,
        '-vn',
        '-acodec',
        'copy',
        output_audio_file_path,
    ])

    yield banner('Done')

    yield (0, 'See files {video} and {audio}'.format(
        video=output_video_file_path,
        audio=output_audio_file_path,
    ))
    return


def banner(message, start_with_newlines=True):
    bar = '#' * 60
    message = '\n'.join(filter(None, [
        '\n\n' if start_with_newlines else None,
        bar,
        message,
        bar,
    ]))
    return (None, message)


if __name__ == '__main__':
    for exit_code, message in main(sys.argv[1:]):
        if message is not None:
            print(message)
        if exit_code is not None:
            if exit_code != 0:
                print('Failed to extract.')
            sys.exit(exit_code)

    print('The program exited unexpectedly.')
    sys.exit(2)
