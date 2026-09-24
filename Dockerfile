# Keep the compiler and Cabal store: Clash needs them at runtime to synthesize
# newly generated network architectures.
FROM haskell:9.10.3

WORKDIR /app

RUN cabal update \
    && cabal install clash-ghc-1.10.2 \
         --install-method=copy --installdir=/usr/local/bin -j2

COPY brain.cabal cabal.project ./
COPY brain.hs Train.hs BrainTrain.hs LinAlg.hs ./
COPY BrainClash.hs BrainClash.template.hs ./
COPY SwitchTraining.hs SwitchBrain.hs SwitchLED.hs ./
COPY DE1SoC.hs ./
COPY DE1SoCDiagnostic.hs ./
COPY tests/ tests/

# Match the Clash compiler's prelude version when resolving project packages.
RUN printf 'constraints: clash-prelude == 1.10.2\n' > cabal.project.local \
    && cabal build all -j2 \
    && cabal exec -- clash --vhdl BrainClash.hs -fclash-hdldir /tmp/brain-hdl-check \
    && rm -rf /tmp/brain-hdl-check

# This is a batch/CLI project, not an HTTP service.
CMD ["cabal", "run", "brain"]