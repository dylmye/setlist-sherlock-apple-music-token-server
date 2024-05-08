FROM public.ecr.aws/lambda/nodejs:20 as builder

WORKDIR /usr/app
COPY .env .swcrc package.json yarn.lock  ./
COPY src ./src
RUN npm install -g yarn
RUN yarn install --frozen-lockfile
RUN yarn build

FROM public.ecr.aws/lambda/nodejs:20
WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=builder /usr/app/dist/* ./
CMD ["index.handler"]
