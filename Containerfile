from registry.fedoraproject.org/fedora-minimal as build

RUN microdnf -y install \
    gcc \
    libffi-devel \
    python3-devel && \
    pip3 install --upgrade \
    pip \
    pip-tools

RUN python -m venv /opt/httpbin
RUN /opt/httpbin/bin/pip install -U pip

ADD . /httpbin
RUN pip-compile --upgrade --extra mainapp --generate-hashes /httpbin/setup.cfg
RUN /opt/httpbin/bin/pip install --no-deps --requirement /httpbin/requirements.txt

ARG APP_VERSION=post1
RUN sed -i -r 's,^(version.*)\"$,\1.'$APP_VERSION'",' /httpbin/pyproject.toml
RUN /opt/httpbin/bin/pip install --no-deps /httpbin

# ----------------------------------------------------------------------------

from registry.fedoraproject.org/fedora-minimal as prod

RUN microdnf -y install python3 && microdnf clean all

ARG APP_VERSION
LABEL name="httpbin"
LABEL version=${APP_VERSION}
LABEL description="A simple HTTP service."
LABEL org.kennethreitz.vendor="Kenneth Reitz"

COPY --chown=65535:65535 --from=build /opt/httpbin /opt/httpbin
WORKDIR /opt/httpbin

COPY --chown=65535:65535 httpbin.bash /opt/httpbin/bin
RUN chmod +x /opt/httpbin/bin/httpbin.bash

EXPOSE 8080
CMD ["/opt/httpbin/bin/httpbin.bash"]

USER 65535
